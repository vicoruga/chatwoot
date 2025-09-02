# Documentación de Arquitectura del Proyecto Chatwoot

## Índice
1. [Información General](#información-general)
2. [Stack Tecnológico](#stack-tecnológico)
3. [Arquitectura de Base de Datos](#arquitectura-de-base-de-datos)
4. [Estructura del Proyecto](#estructura-del-proyecto)
5. [Modelos de Datos Principales](#modelos-de-datos-principales)
6. [Arquitectura Frontend](#arquitectura-frontend)
7. [Arquitectura Backend](#arquitectura-backend)
8. [Flujos de Datos](#flujos-de-datos)
9. [Configuración y Setup](#configuración-y-setup)
10. [Patrones de Desarrollo](#patrones-de-desarrollo)

---

## Información General

**Chatwoot** es una plataforma de soporte al cliente open-source moderna, diseñada como alternativa a Intercom, Zendesk y Salesforce Service Cloud. Es una aplicación completa de gestión de conversaciones omnicanal.

### Características Principales
- Soporte omnicanal (Website, Email, Facebook, Instagram, Twitter, WhatsApp, Telegram, etc.)
- Centro de ayuda integrado
- Automatización con IA (Captain - AI Agent)
- Gestión de equipos y asignaciones
- Reportes y análisis
- Integraciones múltiples

---

## Stack Tecnológico

### Backend
- **Framework**: Ruby on Rails 7.1
- **Lenguaje**: Ruby 3.4.4
- **Base de Datos**: PostgreSQL con extensiones (pg_trgm, pgcrypto, vector)
- **Cache/Sessions**: Redis
- **Jobs en Background**: Sidekiq
- **Autenticación**: Devise + JWT tokens
- **Autorización**: Pundit
- **API**: REST JSON APIs
- **Búsqueda**: Elasticsearch/OpenSearch con Searchkick

### Frontend
- **Framework**: Vue.js 3.5
- **Build Tool**: Vite 5.4
- **Estado**: Vuex 4.1
- **Enrutamiento**: Vue Router 4.4
- **UI**: Tailwind CSS 3.4
- **Lenguaje**: JavaScript/TypeScript
- **Testing**: Vitest

### Infraestructura
- **Contenedores**: Docker + Docker Compose
- **Servidor Web**: Puma
- **Almacenamiento**: Active Storage (AWS S3, Azure Blob, Google Cloud)
- **Monitoreo**: Sentry, New Relic, Datadog (opcional)
- **Deploy**: Heroku, DigitalOcean, auto-deploy

---

## Arquitectura de Base de Datos

### Modelos Principales y Relaciones

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Account   │────│ AccountUser │────│    User     │
│             │    │             │    │             │
└─────────────┘    └─────────────┘    └─────────────┘
        │                                     │
        │          ┌─────────────┐            │
        └──────────│    Inbox    │            │
                   │             │            │
                   └─────────────┘            │
                          │                  │
                          │                  │
                   ┌─────────────┐    ┌─────────────┐
                   │ Conversation│────│   Message   │
                   │             │    │             │
                   └─────────────┘    └─────────────┘
                          │                  │
                          │                  │
                   ┌─────────────┐            │
                   │   Contact   │────────────┘
                   │             │
                   └─────────────┘
```

### Entidades Core

#### Account (Cuentas)
- Representa una organización/empresa
- Contiene configuraciones, límites y características
- Relacionado con usuarios a través de `account_users`

#### User (Usuarios)
- Agentes, administradores y superadmins
- Autenticación via Devise
- Permisos manejados por Pundit

#### Inbox (Buzones)
- Canales de comunicación (Web, Email, Social Media)
- Configuraciones específicas por canal
- Asignación de agentes

#### Conversation (Conversaciones)
- Hilo principal de comunicación
- Estados: open, resolved, pending, snoozed
- Prioridades: low, medium, high, urgent

#### Contact (Contactos)
- Información del cliente/usuario final
- Atributos personalizados
- Historial de conversaciones

#### Message (Mensajes)
- Contenido de comunicación
- Tipos: incoming, outgoing, activity, template
- Adjuntos via Active Storage

---

## Estructura del Proyecto

```
chatwoot/
├── app/
│   ├── controllers/          # Controladores Rails
│   ├── models/              # Modelos ActiveRecord
│   ├── views/               # Vistas Rails + JSON builders
│   ├── services/            # Lógica de negocio
│   ├── jobs/                # Background jobs (Sidekiq)
│   ├── javascript/          # Frontend Vue.js
│   │   ├── dashboard/       # Admin dashboard
│   │   ├── widget/          # Chat widget público
│   │   ├── portal/          # Help center
│   │   └── shared/          # Componentes compartidos
│   ├── builders/            # Response builders
│   ├── dispatchers/         # Event dispatching
│   ├── listeners/           # Event listeners
│   ├── finders/             # Query objects
│   └── policies/            # Autorización Pundit
├── config/
│   ├── routes.rb            # Rutas de la aplicación
│   ├── database.yml         # Configuración DB
│   ├── application.rb       # Configuración Rails
│   └── initializers/        # Inicializadores
├── db/
│   ├── migrate/             # Migraciones
│   └── schema.rb            # Esquema actual
├── lib/                     # Librerías custom
├── spec/                    # Tests RSpec
├── enterprise/              # Características enterprise
└── docs/                    # Documentación
```

---

## Modelos de Datos Principales

### Account
```ruby
class Account < ApplicationRecord
  has_many :account_users
  has_many :users, through: :account_users
  has_many :inboxes
  has_many :conversations
  has_many :contacts
  
  # Configuraciones específicas
  jsonb :custom_attributes
  jsonb :settings
  jsonb :limits
end
```

### Conversation
```ruby
class Conversation < ApplicationRecord
  belongs_to :account
  belongs_to :inbox
  belongs_to :contact
  belongs_to :assignee, class_name: 'User', optional: true
  
  has_many :messages
  
  enum status: { open: 0, resolved: 1, pending: 2, snoozed: 3 }
  enum priority: { low: 0, medium: 1, high: 2, urgent: 3 }
end
```

### Message
```ruby
class Message < ApplicationRecord
  belongs_to :conversation
  belongs_to :sender, polymorphic: true
  
  has_many_attached :attachments
  
  enum message_type: { incoming: 0, outgoing: 1, activity: 2, template: 3 }
  enum status: { sent: 0, delivered: 1, read: 2, failed: 3 }
end
```

### User
```ruby
class User < ApplicationRecord
  devise :database_authenticatable, :registerable, :recoverable
  include DeviseTokenAuth::Concerns::User
  
  has_many :account_users
  has_many :accounts, through: :account_users
  has_many :assigned_conversations, foreign_key: 'assignee_id'
  has_many :messages, as: :sender
end
```

---

## Arquitectura Frontend

### Estructura Vue.js

```
app/javascript/
├── dashboard/               # Admin Dashboard
│   ├── routes/             # Vue Router config
│   ├── store/              # Vuex store modules
│   ├── components/         # Componentes Vue
│   ├── helper/             # Utilidades
│   └── api/                # Cliente API
├── widget/                 # Chat Widget Público
│   ├── store/              # Estado del widget
│   ├── components/         # Componentes del widget
│   └── api/                # API calls del widget
├── portal/                 # Help Center
└── shared/                 # Código compartido
    ├── constants/
    ├── helpers/
    └── mixins/
```

### Gestión de Estado (Vuex)

#### Módulos Principales
- **auth**: Autenticación y usuario actual
- **conversations**: Estado de conversaciones
- **contacts**: Gestión de contactos
- **inboxes**: Configuración de buzones
- **teams**: Gestión de equipos
- **agents**: Gestión de agentes

#### Patrón de Estado para Conversaciones
```javascript
const state = {
  allConversations: [],
  selectedChatId: null,
  chatStatusFilter: 'open',
  messagesLoading: false,
  uiFlags: {
    isFetching: false,
    isUpdating: false
  }
}
```

### Componentes Principales

#### Dashboard
- **ConversationView**: Vista principal de conversaciones
- **ContactPanel**: Panel de información del contacto
- **MessageList**: Lista de mensajes
- **ReplyBox**: Caja de respuesta
- **SettingsPanel**: Configuraciones

#### Widget
- **ChatWidget**: Widget embebido
- **MessageBubble**: Burbujas de mensaje
- **PreChatForm**: Formulario pre-chat

---

## Arquitectura Backend

### Controladores por Módulo

#### API Structure
```
/api/v1/
├── accounts/{account_id}/
│   ├── conversations/
│   ├── contacts/
│   ├── inboxes/
│   ├── agents/
│   ├── teams/
│   └── reports/
└── public/
    └── messages/           # Widget API
```

### Servicios (Service Objects)

Los servicios encapsulan lógica de negocio compleja:

```ruby
# app/services/messages/message_builder.rb
class Messages::MessageBuilder
  def initialize(user, conversation, params)
    @user = user
    @conversation = conversation
    @params = params
  end
  
  def perform
    # Lógica de creación de mensaje
    # Procesamiento de adjuntos
    # Notificaciones
    # Webhooks
  end
end
```

### Jobs en Background

#### Tipos de Jobs
- **MessageBroadcastJob**: Difusión de mensajes en tiempo real
- **SendReplyJob**: Envío de respuestas a canales externos
- **ActivityMessageJob**: Mensajes de actividad del sistema
- **ReportsJob**: Generación de reportes
- **WebhookJob**: Envío de webhooks

### Event System (Wisper)

Patrón pub/sub para eventos:

```ruby
class Conversation
  include Wisper::Publisher
  
  after_update :broadcast_update
  
  private
  
  def broadcast_update
    broadcast(:conversation_updated, self)
  end
end
```

---

## Flujos de Datos

### Flujo de Mensaje Entrante

1. **Webhook/API** recibe mensaje
2. **ContactInboxBuilder** encuentra o crea contacto
3. **ConversationBuilder** encuentra o crea conversación
4. **MessageBuilder** crea el mensaje
5. **MessageBroadcastJob** difunde via WebSocket
6. **Notificaciones** enviadas a agentes
7. **Webhooks** enviados a integraciones

### Flujo de Mensaje Saliente

1. **Frontend** envía mensaje via API
2. **MessagesController** valida y procesa
3. **MessageBuilder** crea mensaje en DB
4. **SendReplyJob** envía a canal externo
5. **MessageBroadcastJob** actualiza UI
6. **Tracking** de delivery/read status

### Flujo de Autenticación

1. **Login** via `/auth/sign_in`
2. **JWT Token** generado y enviado
3. **Frontend** almacena token
4. **API calls** incluyen token en headers
5. **DeviseTokenAuth** valida token
6. **Pundit** autoriza acciones

---

## Configuración y Setup

### Variables de Entorno Principales

```bash
# Base de Datos
DATABASE_URL=postgresql://user:pass@localhost/chatwoot
REDIS_URL=redis://localhost:6379

# Almacenamiento
ACTIVE_STORAGE_SERVICE=local # o aws, azure, gcs
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_REGION=
AWS_S3_BUCKET_NAME=

# Email
SMTP_ADDRESS=
SMTP_PORT=587
SMTP_EMAIL=
SMTP_PASSWORD=

# Frontend
FRONTEND_URL=http://localhost:3000

# Características
ENABLE_ACCOUNT_SIGNUP=false
DIRECT_UPLOADS_ENABLED=true
```

### Setup de Desarrollo

```bash
# 1. Clonar repositorio
git clone https://github.com/chatwoot/chatwoot.git

# 2. Instalar dependencias
bundle install
pnpm install

# 3. Configurar base de datos
rails db:setup

# 4. Generar datos de prueba
rails db:seed

# 5. Iniciar servicios
foreman start -f Procfile.dev
```

### Docker Setup

```yaml
# docker-compose.yml
version: '3'
services:
  postgres:
    image: postgres:13
    environment:
      POSTGRES_DB: chatwoot
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: password
  
  redis:
    image: redis:6-alpine
  
  app:
    build: .
    ports:
      - "3000:3000"
    depends_on:
      - postgres
      - redis
```

---

## Patrones de Desarrollo

### 1. Service Objects
Encapsulan lógica de negocio compleja:
```ruby
class ContactBuilder
  def initialize(source_id:, inbox:, contact_attributes:)
    # ...
  end
  
  def perform
    # Lógica de creación/actualización
  end
end
```

### 2. Builder Pattern
Para construcción de objetos complejos:
```ruby
class ConversationBuilder
  def initialize(contact_inbox:, params:)
    # ...
  end
  
  def perform
    # Construcción de conversación
  end
end
```

### 3. Finder Objects
Para queries complejas:
```ruby
class ConversationFinder
  def initialize(current_user, params)
    # ...
  end
  
  def perform
    # Query optimizada
  end
end
```

### 4. Policy Objects (Pundit)
Para autorización:
```ruby
class ConversationPolicy
  def update?
    user.agent? && conversation.account == user.account
  end
end
```

### 5. Presenter Objects
Para formateo de datos:
```ruby
class ConversationPresenter
  def initialize(conversation)
    @conversation = conversation
  end
  
  def display_title
    # Lógica de presentación
  end
end
```

### 6. Event Listeners
Para efectos secundarios:
```ruby
class ConversationListener
  def conversation_updated(conversation)
    # Efectos posteriores a actualización
  end
end
```

---

## Patrones Frontend

### 1. Composables Vue 3
```javascript
// composables/useConversations.js
export function useConversations() {
  const conversations = ref([])
  const loading = ref(false)
  
  const fetchConversations = async () => {
    // Lógica de fetch
  }
  
  return {
    conversations,
    loading,
    fetchConversations
  }
}
```

### 2. Store Modules
```javascript
// store/modules/conversations.js
const actions = {
  async fetchConversations({ commit }, filters) {
    const response = await ConversationAPI.get(filters)
    commit('SET_CONVERSATIONS', response.data)
  }
}
```

### 3. API Client Pattern
```javascript
// api/conversation.js
class ConversationApi extends ApiClient {
  get(filters) {
    return axios.get(this.url, { params: filters })
  }
}
```

---

## Testing

### Backend (RSpec)
```ruby
# spec/services/message_builder_spec.rb
RSpec.describe Messages::MessageBuilder do
  describe '#perform' do
    it 'creates a message successfully' do
      # Test implementation
    end
  end
end
```

### Frontend (Vitest)
```javascript
// spec/dashboard/conversation.spec.js
describe('ConversationView', () => {
  it('renders conversations correctly', () => {
    // Test implementation
  })
})
```

---

## Deployment

### Heroku
- One-click deploy disponible
- Auto-scaling con Judoscale
- Add-ons: Postgres, Redis, SendGrid

### DigitalOcean
- 1-Click Kubernetes deployment
- Managed databases
- Spaces para almacenamiento

### Docker
- Multi-stage builds
- Production-ready images
- Health checks incluidos

---

Esta documentación proporciona una visión completa de la arquitectura de Chatwoot para que los desarrolladores puedan entender rápidamente cómo funciona el sistema y comenzar a contribuir de manera efectiva.
