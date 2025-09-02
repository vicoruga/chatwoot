# Diagramas de Base de Datos y Flujos - Chatwoot

## Diagrama de Entidad-Relación (ERD) Detallado

```mermaid
erDiagram
    Account {
        int id PK
        string name
        string domain
        string support_email
        bigint feature_flags
        jsonb custom_attributes
        jsonb settings
        int status
        timestamp created_at
        timestamp updated_at
    }
    
    User {
        bigint id PK
        string email
        string encrypted_password
        string name
        string display_name
        string avatar_url
        int availability
        timestamp created_at
        timestamp updated_at
    }
    
    AccountUser {
        bigint id PK
        bigint account_id FK
        bigint user_id FK
        int role
        bigint inviter_id
        int availability
        boolean auto_offline
        timestamp active_at
        timestamp created_at
        timestamp updated_at
    }
    
    Inbox {
        bigint id PK
        string channel_type
        string name
        bigint account_id FK
        jsonb channel_data
        jsonb additional_attributes
        boolean enable_auto_assignment
        boolean enable_email_collect
        boolean greeting_enabled
        text greeting_message
        timestamp created_at
        timestamp updated_at
    }
    
    Contact {
        bigint id PK
        string name
        string email
        string phone_number
        string identifier
        bigint account_id FK
        jsonb additional_attributes
        jsonb custom_attributes
        timestamp created_at
        timestamp updated_at
    }
    
    ContactInbox {
        bigint id PK
        bigint contact_id FK
        bigint inbox_id FK
        string source_id
        jsonb hmac_verified
        jsonb pubsub_token
        timestamp created_at
        timestamp updated_at
    }
    
    Conversation {
        bigint id PK
        int display_id
        uuid uuid
        bigint account_id FK
        bigint inbox_id FK
        bigint contact_id FK
        bigint contact_inbox_id FK
        bigint assignee_id FK
        int status
        int priority
        jsonb additional_attributes
        jsonb custom_attributes
        timestamp agent_last_seen_at
        timestamp contact_last_seen_at
        timestamp last_activity_at
        timestamp first_reply_created_at
        timestamp created_at
        timestamp updated_at
    }
    
    Message {
        bigint id PK
        string content
        bigint account_id FK
        bigint inbox_id FK
        bigint conversation_id FK
        int message_type
        string content_type
        int status
        jsonb content_attributes
        string sender_type
        bigint sender_id
        jsonb external_source_ids
        string source_id
        timestamp created_at
        timestamp updated_at
    }
    
    Team {
        bigint id PK
        string name
        string description
        bigint account_id FK
        boolean allow_auto_assign
        timestamp created_at
        timestamp updated_at
    }
    
    TeamMember {
        bigint id PK
        bigint team_id FK
        bigint user_id FK
        timestamp created_at
        timestamp updated_at
    }
    
    InboxMember {
        bigint id PK
        bigint user_id FK
        bigint inbox_id FK
        timestamp created_at
        timestamp updated_at
    }
    
    Label {
        bigint id PK
        string title
        string description
        string color
        bigint account_id FK
        boolean show_on_sidebar
        timestamp created_at
        timestamp updated_at
    }
    
    ConversationLabel {
        bigint id PK
        bigint conversation_id FK
        bigint label_id FK
        bigint account_id FK
        timestamp created_at
        timestamp updated_at
    }
    
    Attachment {
        bigint id PK
        string file_type
        string external_url
        string coordinates_lat
        string coordinates_long
        bigint message_id FK
        bigint account_id FK
        timestamp created_at
        timestamp updated_at
    }
    
    CannedResponse {
        bigint id PK
        bigint account_id FK
        string short_code
        text content
        timestamp created_at
        timestamp updated_at
    }
    
    Webhook {
        bigint id PK
        bigint account_id FK
        bigint inbox_id FK
        string url
        jsonb subscriptions
        timestamp created_at
        timestamp updated_at
    }
    
    Account ||--o{ AccountUser : has
    User ||--o{ AccountUser : belongs_to
    Account ||--o{ Inbox : has
    Account ||--o{ Contact : has
    Account ||--o{ Conversation : has
    Account ||--o{ Team : has
    Account ||--o{ Label : has
    Account ||--o{ CannedResponse : has
    Account ||--o{ Webhook : has
    
    Inbox ||--o{ ContactInbox : has
    Contact ||--o{ ContactInbox : has
    Inbox ||--o{ Conversation : has
    Contact ||--o{ Conversation : has
    ContactInbox ||--o{ Conversation : has
    User ||--o{ Conversation : assigned_to
    
    Conversation ||--o{ Message : has
    Inbox ||--o{ Message : has
    Account ||--o{ Message : has
    
    Team ||--o{ TeamMember : has
    User ||--o{ TeamMember : belongs_to
    
    Inbox ||--o{ InboxMember : has
    User ||--o{ InboxMember : belongs_to
    
    Conversation ||--o{ ConversationLabel : has
    Label ||--o{ ConversationLabel : belongs_to
    
    Message ||--o{ Attachment : has
```

## Flujo de Datos Detallado

### 1. Flujo de Creación de Conversación

```mermaid
sequenceDiagram
    participant Client as Cliente/Widget
    participant API as API Controller
    participant Builder as ConversationBuilder
    participant ContactBuilder as ContactBuilder
    participant DB as Database
    participant WS as WebSocket
    participant Job as Background Job
    
    Client->>API: POST /public/api/v1/inboxes/:id/contacts
    API->>ContactBuilder: build_contact(params)
    ContactBuilder->>DB: find_or_create contact
    ContactBuilder->>DB: create contact_inbox
    ContactBuilder-->>API: contact_inbox
    
    API->>Builder: perform(contact_inbox, params)
    Builder->>DB: create conversation
    Builder->>DB: create initial message
    Builder-->>API: conversation
    
    API->>Job: MessageBroadcastJob.perform_later
    Job->>WS: broadcast to agents
    Job->>Job: SendReplyJob (if auto-reply)
    
    API-->>Client: conversation data
```

### 2. Flujo de Mensaje Entrante (Webhook)

```mermaid
sequenceDiagram
    participant Channel as Canal Externo
    participant Webhook as Webhook Controller
    participant Finder as ContactInboxFinder
    participant Builder as MessageBuilder
    participant DB as Database
    participant WS as WebSocket
    participant Notification as NotificationService
    
    Channel->>Webhook: POST /webhooks/whatsapp
    Webhook->>Finder: find_contact_inbox(source_id)
    Finder->>DB: query contact_inbox
    Finder-->>Webhook: contact_inbox
    
    Webhook->>Builder: perform(contact_inbox, message_params)
    Builder->>DB: create message
    Builder->>DB: update conversation.last_activity_at
    Builder-->>Webhook: message
    
    Webhook->>WS: broadcast message
    Webhook->>Notification: notify_agents
    Webhook-->>Channel: 200 OK
```

### 3. Flujo de Respuesta de Agente

```mermaid
sequenceDiagram
    participant Agent as Agente (Dashboard)
    participant API as Messages API
    participant Policy as MessagePolicy
    participant Builder as MessageBuilder
    participant DB as Database
    participant Job as SendReplyJob
    participant Channel as Canal Externo
    participant WS as WebSocket
    
    Agent->>API: POST /api/v1/accounts/:id/conversations/:id/messages
    API->>Policy: authorize(create?)
    Policy-->>API: allowed
    
    API->>Builder: perform(conversation, message_params)
    Builder->>DB: create outgoing message
    Builder->>DB: update conversation
    Builder-->>API: message
    
    API->>Job: SendReplyJob.perform_later
    Job->>Channel: send message via API
    Job->>DB: update message status
    
    API->>WS: broadcast to conversation
    API-->>Agent: message response
```

## Diagrama de Arquitectura de Sistema

```mermaid
graph TB
    subgraph "Frontend Applications"
        Dashboard[Vue.js Dashboard]
        Widget[Chat Widget]
        Portal[Help Center]
        Mobile[Mobile App]
    end
    
    subgraph "Load Balancer"
        LB[Nginx/CloudFlare]
    end
    
    subgraph "Application Layer"
        Rails[Rails Application]
        API[API Server]
        WS[WebSocket Server]
    end
    
    subgraph "Background Processing"
        Sidekiq[Sidekiq Workers]
        Scheduler[Sidekiq Cron]
    end
    
    subgraph "Data Layer"
        PostgreSQL[(PostgreSQL)]
        Redis[(Redis)]
        Search[(Elasticsearch)]
    end
    
    subgraph "External Storage"
        S3[AWS S3/Azure Blob]
        CDN[CloudFront CDN]
    end
    
    subgraph "External Services"
        Email[SMTP Server]
        Push[FCM/APNS]
        WhatsApp[WhatsApp API]
        Facebook[Facebook API]
        Slack[Slack API]
    end
    
    subgraph "Monitoring"
        Sentry[Error Tracking]
        APM[Performance Monitoring]
        Logs[Log Aggregation]
    end
    
    Dashboard --> LB
    Widget --> LB
    Portal --> LB
    Mobile --> API
    
    LB --> Rails
    LB --> API
    LB --> WS
    
    Rails --> PostgreSQL
    Rails --> Redis
    Rails --> Search
    API --> PostgreSQL
    API --> Redis
    WS --> Redis
    
    Rails --> Sidekiq
    Sidekiq --> PostgreSQL
    Sidekiq --> Email
    Sidekiq --> Push
    Sidekiq --> WhatsApp
    Sidekiq --> Facebook
    Sidekiq --> Slack
    
    Rails --> S3
    S3 --> CDN
    
    Rails --> Sentry
    Rails --> APM
    Rails --> Logs
```

## Modelo de Estados de Conversación

```mermaid
stateDiagram-v2
    [*] --> Open : New message received
    
    Open --> Pending : Agent starts working
    Open --> Resolved : Agent resolves
    Open --> Snoozed : Agent snoozes
    
    Pending --> Open : Customer replies
    Pending --> Resolved : Agent resolves
    Pending --> Snoozed : Agent snoozes
    
    Resolved --> Open : Customer replies
    Resolved --> Open : Agent reopens
    
    Snoozed --> Open : Snooze time expires
    Snoozed --> Open : Customer replies
    Snoozed --> Open : Agent reopens
    Snoozed --> Resolved : Agent resolves
    
    state Open {
        [*] --> Unassigned
        Unassigned --> Assigned : Auto/Manual assignment
        Assigned --> Unassigned : Agent removed
    }
```

## Flujo de Autenticación y Autorización

```mermaid
sequenceDiagram
    participant User as Usuario
    participant Frontend as Vue.js App
    participant Auth as Auth Controller
    participant JWT as JWT Service
    participant DB as Database
    participant API as API Controller
    participant Policy as Pundit Policy
    
    User->>Frontend: Login credentials
    Frontend->>Auth: POST /auth/sign_in
    Auth->>DB: validate credentials
    DB-->>Auth: user data
    Auth->>JWT: generate token
    JWT-->>Auth: access token
    Auth-->>Frontend: token + user data
    
    Frontend->>Frontend: store token
    
    User->>Frontend: API request
    Frontend->>API: request + Bearer token
    API->>JWT: validate token
    JWT-->>API: user data
    API->>Policy: authorize action
    Policy-->>API: permission result
    API->>DB: execute if authorized
    DB-->>API: response data
    API-->>Frontend: API response
```

## Estructura de Datos de Mensaje

```mermaid
classDiagram
    class Message {
        +bigint id
        +string content
        +int message_type
        +string content_type
        +int status
        +jsonb content_attributes
        +string sender_type
        +bigint sender_id
        +timestamp created_at
        +validate_content()
        +broadcast()
        +mark_as_read()
    }
    
    class MessageType {
        <<enumeration>>
        INCOMING : 0
        OUTGOING : 1
        ACTIVITY : 2
        TEMPLATE : 3
    }
    
    class MessageStatus {
        <<enumeration>>
        SENT : 0
        DELIVERED : 1
        READ : 2
        FAILED : 3
    }
    
    class ContentType {
        <<enumeration>>
        TEXT
        INPUT_EMAIL
        INPUT_TEXTAREA
        INPUT_SELECT
        CARDS
        FORM
        ARTICLE
        INCOMING_EMAIL
    }
    
    class Attachment {
        +bigint id
        +string file_type
        +string data_url
        +string thumb_url
        +integer file_size
        +integer width
        +integer height
        +process_file()
    }
    
    class Sender {
        <<interface>>
        +User
        +Contact
    }
    
    Message --> MessageType
    Message --> MessageStatus
    Message --> ContentType
    Message --> Attachment : has_many
    Message --> Sender : polymorphic
```

## Patrón de Event Broadcasting

```mermaid
graph TD
    Event[Rails Event] --> Wisper[Wisper Publisher]
    Wisper --> Listener1[ConversationListener]
    Wisper --> Listener2[NotificationListener]
    Wisper --> Listener3[WebhookListener]
    
    Listener1 --> WS1[WebSocket Broadcast]
    Listener2 --> Push[Push Notification]
    Listener2 --> Email[Email Notification]
    Listener3 --> Webhook[External Webhook]
    
    WS1 --> Dashboard[Update Dashboard]
    Push --> Mobile[Mobile App]
    Email --> Agent[Agent Email]
    Webhook --> Integration[External Service]
```

## Configuración de Canales

```mermaid
graph LR
    subgraph "Channel Types"
        Website[Website Widget]
        EmailChannel[Email]
        WhatsApp[WhatsApp]
        Facebook[Facebook Messenger]
        Twitter[Twitter]
        Instagram[Instagram]
        Telegram[Telegram]
        SMS[SMS]
        API[API Channel]
    end
    
    subgraph "Inbox Configuration"
        InboxSetup[Inbox Setup]
        ChannelData[Channel Specific Data]
        AgentAssignment[Agent Assignment]
        BusinessHours[Business Hours]
        Greeting[Greeting Messages]
        CSAT[CSAT Settings]
    end
    
    Website --> InboxSetup
    EmailChannel --> InboxSetup
    WhatsApp --> InboxSetup
    Facebook --> InboxSetup
    
    InboxSetup --> ChannelData
    InboxSetup --> AgentAssignment
    InboxSetup --> BusinessHours
    InboxSetup --> Greeting
    InboxSetup --> CSAT
```

Este documento complementa la documentación principal con diagramas visuales que ayudan a entender mejor la estructura de datos y los flujos del sistema Chatwoot.
