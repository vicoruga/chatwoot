# Guía de Desarrollo para Chatwoot

## Índice
1. [Setup Inicial para Desarrolladores](#setup-inicial-para-desarrolladores)
2. [Estructura de Código y Convenciones](#estructura-de-código-y-convenciones)
3. [Desarrollo Backend (Rails)](#desarrollo-backend-rails)
4. [Desarrollo Frontend (Vue.js)](#desarrollo-frontend-vuejs)
5. [Trabajando con la Base de Datos](#trabajando-con-la-base-de-datos)
6. [Testing y Calidad de Código](#testing-y-calidad-de-código)
7. [Debugging y Troubleshooting](#debugging-y-troubleshooting)
8. [Deployment y DevOps](#deployment-y-devops)
9. [Contribución y Best Practices](#contribución-y-best-practices)

---

## Setup Inicial para Desarrolladores

### Prerrequisitos

```bash
# Ruby Version Manager (rbenv recomendado)
rbenv install 3.4.4
rbenv global 3.4.4

# Node.js Version Manager
nvm install 23
nvm use 23

# Package Manager
npm install -g pnpm@10.2.0

# PostgreSQL
brew install postgresql@13  # macOS
sudo apt install postgresql-13  # Ubuntu

# Redis
brew install redis  # macOS
sudo apt install redis-server  # Ubuntu
```

### Configuración del Proyecto

```bash
# 1. Fork y clonar el repositorio
git clone https://github.com/TU_USUARIO/chatwoot.git
cd chatwoot

# 2. Agregar upstream remote
git remote add upstream https://github.com/chatwoot/chatwoot.git

# 3. Instalar dependencias Ruby
bundle install

# 4. Instalar dependencias Node.js
pnpm install

# 5. Configurar variables de entorno
cp .env.example .env
# Editar .env con tu configuración local

# 6. Preparar base de datos
rails db:create
rails db:schema:load
rails db:seed

# 7. Configurar datos de prueba (opcional)
bundle exec rails runner db/seed_data/01_sample_seed_data.rb
```

### Variables de Entorno para Desarrollo

```bash
# .env
DATABASE_URL=postgresql://postgres@localhost:5432/chatwoot_development
REDIS_URL=redis://localhost:6379
SECRET_KEY_BASE=tu_secret_key_aqui
FRONTEND_URL=http://localhost:3000

# Para desarrollo local del widget
WEBPACKER_DEV_SERVER_HOST=0.0.0.0
WEBPACKER_DEV_SERVER_PUBLIC=localhost:3035

# Habilitar características
ENABLE_ACCOUNT_SIGNUP=true
DIRECT_UPLOADS_ENABLED=true

# Email (para desarrollo)
SMTP_ADDRESS=localhost
SMTP_PORT=1025
MAILER_SENDER_EMAIL=no-reply@chatwoot.local

# Almacenamiento local
ACTIVE_STORAGE_SERVICE=local
```

### Comandos de Desarrollo

```bash
# Iniciar todos los servicios (recomendado)
foreman start -f Procfile.dev

# O iniciar servicios individualmente:
# Rails server
rails server -p 3000

# Vite dev server (frontend)
bin/vite dev

# Sidekiq (background jobs)
bundle exec sidekiq

# Redis
redis-server

# PostgreSQL
brew services start postgresql@13
```

---

## Estructura de Código y Convenciones

### Convenciones de Nomenclatura

#### Ruby/Rails
```ruby
# Clases: PascalCase
class MessageBuilder
end

# Métodos y variables: snake_case
def create_contact_inbox
  contact_inbox = ContactInbox.new
end

# Constantes: SCREAMING_SNAKE_CASE
MAX_MESSAGE_LENGTH = 10_000

# Archivos: snake_case
# app/services/messages/message_builder.rb
```

#### JavaScript/Vue.js
```javascript
// Componentes Vue: PascalCase
// ConversationView.vue

// Variables y funciones: camelCase
const conversationId = 123
const fetchConversations = () => {}

// Constantes: SCREAMING_SNAKE_CASE
const API_BASE_URL = '/api/v1'

// Archivos: camelCase o kebab-case
// conversationView.js o conversation-view.js
```

### Organización de Archivos

#### Backend Structure
```
app/
├── controllers/
│   ├── api/v1/accounts/          # API controllers por cuenta
│   ├── public/api/v1/            # API público (widget)
│   └── super_admin/              # Panel super admin
├── models/
│   ├── concerns/                 # Módulos reutilizables
│   └── *.rb                      # Modelos ActiveRecord
├── services/
│   ├── messages/                 # Servicios de mensajes
│   ├── contacts/                 # Servicios de contactos
│   └── conversations/            # Servicios de conversaciones
├── jobs/
│   ├── message_broadcast_job.rb
│   └── send_reply_job.rb
├── policies/                     # Autorización Pundit
├── builders/                     # Objetos builder
├── finders/                      # Query objects
└── listeners/                    # Event listeners
```

#### Frontend Structure
```
app/javascript/
├── dashboard/                    # Admin dashboard
│   ├── components/              # Componentes Vue
│   │   ├── layout/             # Layout components
│   │   ├── widgets/            # Widget components
│   │   └── ui/                 # UI components
│   ├── store/                  # Vuex store
│   │   ├── modules/            # Store modules
│   │   └── index.js            # Store config
│   ├── routes/                 # Vue Router
│   ├── api/                    # API clients
│   ├── helper/                 # Utilidades
│   └── constants/              # Constantes
├── widget/                     # Chat widget
├── portal/                     # Help center
└── shared/                     # Código compartido
    ├── components/
    ├── constants/
    ├── helpers/
    └── mixins/
```

---

## Desarrollo Backend (Rails)

### Creando un Nuevo Modelo

```ruby
# 1. Generar migración
rails generate migration CreateCustomFields name:string field_type:integer account:references

# 2. Editar migración
class CreateCustomFields < ActiveRecord::Migration[7.1]
  def change
    create_table :custom_fields do |t|
      t.string :name, null: false
      t.integer :field_type, default: 0
      t.references :account, null: false, foreign_key: true
      t.jsonb :field_options, default: {}
      
      t.timestamps
    end
    
    add_index :custom_fields, [:account_id, :name], unique: true
  end
end

# 3. Crear modelo
# app/models/custom_field.rb
class CustomField < ApplicationRecord
  belongs_to :account
  
  validates :name, presence: true, uniqueness: { scope: :account_id }
  validates :field_type, presence: true
  
  enum field_type: { text: 0, number: 1, date: 2, select: 3 }
  
  scope :active, -> { where(active: true) }
end

# 4. Ejecutar migración
rails db:migrate
```

### Creando un Service Object

```ruby
# app/services/custom_fields/field_builder.rb
class CustomFields::FieldBuilder
  include Rails.application.routes.url_helpers
  
  def initialize(account:, params:)
    @account = account
    @params = params
  end
  
  def perform
    ActiveRecord::Base.transaction do
      custom_field = build_custom_field
      validate_field_options
      custom_field.save!
      
      trigger_field_created_event(custom_field)
      custom_field
    end
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "Failed to create custom field: #{e.message}"
    raise e
  end
  
  private
  
  attr_reader :account, :params
  
  def build_custom_field
    account.custom_fields.build(field_params)
  end
  
  def field_params
    params.permit(:name, :field_type, :required, field_options: {})
  end
  
  def validate_field_options
    return unless params[:field_type] == 'select'
    
    options = params.dig(:field_options, :options)
    raise ArgumentError, 'Select field requires options' if options.blank?
  end
  
  def trigger_field_created_event(custom_field)
    Rails.application.events.publish('custom_field.created', {
      account: account,
      custom_field: custom_field,
      user: Current.user
    })
  end
end
```

### Creando un Controller

```ruby
# app/controllers/api/v1/accounts/custom_fields_controller.rb
class Api::V1::Accounts::CustomFieldsController < Api::V1::Accounts::BaseController
  before_action :set_custom_field, only: [:show, :update, :destroy]
  before_action :check_authorization
  
  def index
    @custom_fields = Current.account.custom_fields
                            .includes(:account)
                            .page(params[:page])
                            .per(params[:per_page])
  end
  
  def show; end
  
  def create
    @custom_field = CustomFields::FieldBuilder.new(
      account: Current.account,
      params: custom_field_params
    ).perform
    
    render json: @custom_field, status: :created
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.message }, status: :unprocessable_entity
  end
  
  def update
    if @custom_field.update(custom_field_params)
      render json: @custom_field
    else
      render json: { errors: @custom_field.errors }, status: :unprocessable_entity
    end
  end
  
  def destroy
    @custom_field.destroy!
    head :no_content
  end
  
  private
  
  def set_custom_field
    @custom_field = Current.account.custom_fields.find(params[:id])
  end
  
  def custom_field_params
    params.require(:custom_field).permit(:name, :field_type, :required, field_options: {})
  end
  
  def check_authorization
    authorize :custom_field
  end
end
```

### Creando Policies (Pundit)

```ruby
# app/policies/custom_field_policy.rb
class CustomFieldPolicy < ApplicationPolicy
  def index?
    @user.administrator? || @user.agent?
  end
  
  def show?
    index?
  end
  
  def create?
    @user.administrator?
  end
  
  def update?
    create?
  end
  
  def destroy?
    create?
  end
  
  class Scope < Scope
    def resolve
      if user.administrator?
        scope.all
      else
        scope.none
      end
    end
  end
end
```

### Background Jobs

```ruby
# app/jobs/custom_field_sync_job.rb
class CustomFieldSyncJob < ApplicationJob
  queue_as :default
  
  def perform(custom_field_id, action = 'created')
    custom_field = CustomField.find(custom_field_id)
    
    case action
    when 'created'
      sync_field_creation(custom_field)
    when 'updated'
      sync_field_update(custom_field)
    when 'destroyed'
      sync_field_deletion(custom_field)
    end
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error "CustomField not found: #{e.message}"
  end
  
  private
  
  def sync_field_creation(custom_field)
    # Integrar con servicios externos
    # Notificar webhooks
    # Actualizar caches
  end
end
```

---

## Desarrollo Frontend (Vue.js)

### Creando un Componente Vue

```vue
<!-- app/javascript/dashboard/components/custom-fields/CustomFieldForm.vue -->
<template>
  <div class="custom-field-form">
    <div class="form-header">
      <h3 class="text-lg font-semibold">
        {{ isEdit ? $t('CUSTOM_FIELDS.EDIT_TITLE') : $t('CUSTOM_FIELDS.CREATE_TITLE') }}
      </h3>
    </div>
    
    <form @submit.prevent="onSubmit" class="space-y-4">
      <div class="form-group">
        <label for="field-name" class="block text-sm font-medium">
          {{ $t('CUSTOM_FIELDS.FORM.NAME.LABEL') }}
        </label>
        <input
          id="field-name"
          v-model="fieldData.name"
          type="text"
          class="form-input"
          :placeholder="$t('CUSTOM_FIELDS.FORM.NAME.PLACEHOLDER')"
          required
        />
        <span v-if="errors.name" class="error-message">
          {{ errors.name[0] }}
        </span>
      </div>
      
      <div class="form-group">
        <label for="field-type" class="block text-sm font-medium">
          {{ $t('CUSTOM_FIELDS.FORM.TYPE.LABEL') }}
        </label>
        <select
          id="field-type"
          v-model="fieldData.field_type"
          class="form-select"
          @change="onTypeChange"
        >
          <option value="">{{ $t('CUSTOM_FIELDS.FORM.TYPE.PLACEHOLDER') }}</option>
          <option v-for="type in fieldTypes" :key="type.value" :value="type.value">
            {{ type.label }}
          </option>
        </select>
      </div>
      
      <div v-if="fieldData.field_type === 'select'" class="form-group">
        <label class="block text-sm font-medium">
          {{ $t('CUSTOM_FIELDS.FORM.OPTIONS.LABEL') }}
        </label>
        <div v-for="(option, index) in fieldOptions" :key="index" class="option-item">
          <input
            v-model="option.value"
            type="text"
            class="form-input"
            :placeholder="$t('CUSTOM_FIELDS.FORM.OPTIONS.PLACEHOLDER')"
          />
          <button
            type="button"
            @click="removeOption(index)"
            class="btn-remove-option"
          >
            <i class="icon ion-ios-close" />
          </button>
        </div>
        <button
          type="button"
          @click="addOption"
          class="btn-add-option"
        >
          {{ $t('CUSTOM_FIELDS.FORM.OPTIONS.ADD') }}
        </button>
      </div>
      
      <div class="form-actions">
        <button
          type="button"
          @click="onCancel"
          class="btn btn-secondary"
        >
          {{ $t('CUSTOM_FIELDS.FORM.CANCEL') }}
        </button>
        <button
          type="submit"
          :disabled="isSubmitting"
          class="btn btn-primary"
        >
          <span v-if="isSubmitting" class="spinner" />
          {{ isEdit ? $t('CUSTOM_FIELDS.FORM.UPDATE') : $t('CUSTOM_FIELDS.FORM.CREATE') }}
        </button>
      </div>
    </form>
  </div>
</template>

<script>
import { mapActions } from 'vuex'
import { required } from '@vuelidate/validators'
import { useVuelidate } from '@vuelidate/core'

export default {
  name: 'CustomFieldForm',
  props: {
    customField: {
      type: Object,
      default: () => ({})
    }
  },
  setup() {
    return { $v: useVuelidate() }
  },
  data() {
    return {
      fieldData: {
        name: '',
        field_type: '',
        required: false,
        field_options: {}
      },
      fieldOptions: [{ value: '' }],
      isSubmitting: false,
      errors: {}
    }
  },
  computed: {
    isEdit() {
      return !!this.customField.id
    },
    fieldTypes() {
      return [
        { value: 'text', label: this.$t('CUSTOM_FIELDS.TYPES.TEXT') },
        { value: 'number', label: this.$t('CUSTOM_FIELDS.TYPES.NUMBER') },
        { value: 'date', label: this.$t('CUSTOM_FIELDS.TYPES.DATE') },
        { value: 'select', label: this.$t('CUSTOM_FIELDS.TYPES.SELECT') }
      ]
    }
  },
  validations() {
    return {
      fieldData: {
        name: { required },
        field_type: { required }
      }
    }
  },
  mounted() {
    if (this.isEdit) {
      this.populateForm()
    }
  },
  methods: {
    ...mapActions('customFields', ['createCustomField', 'updateCustomField']),
    
    populateForm() {
      this.fieldData = { ...this.customField }
      if (this.fieldData.field_type === 'select') {
        this.fieldOptions = this.fieldData.field_options.options || [{ value: '' }]
      }
    },
    
    onTypeChange() {
      if (this.fieldData.field_type !== 'select') {
        this.fieldOptions = [{ value: '' }]
      }
    },
    
    addOption() {
      this.fieldOptions.push({ value: '' })
    },
    
    removeOption(index) {
      if (this.fieldOptions.length > 1) {
        this.fieldOptions.splice(index, 1)
      }
    },
    
    async onSubmit() {
      this.$v.$touch()
      if (this.$v.$invalid) return
      
      this.isSubmitting = true
      this.errors = {}
      
      try {
        const payload = { ...this.fieldData }
        
        if (payload.field_type === 'select') {
          payload.field_options = {
            options: this.fieldOptions.filter(opt => opt.value.trim())
          }
        }
        
        if (this.isEdit) {
          await this.updateCustomField({ id: this.customField.id, ...payload })
        } else {
          await this.createCustomField(payload)
        }
        
        this.$emit('success')
        this.showAlert(this.$t('CUSTOM_FIELDS.SUCCESS_MESSAGE'))
      } catch (error) {
        this.errors = error.response?.data?.errors || {}
        this.showAlert(this.$t('CUSTOM_FIELDS.ERROR_MESSAGE'), 'error')
      } finally {
        this.isSubmitting = false
      }
    },
    
    onCancel() {
      this.$emit('cancel')
    }
  }
}
</script>

<style scoped>
.custom-field-form {
  @apply bg-white p-6 rounded-lg shadow;
}

.form-group {
  @apply space-y-2;
}

.form-input, .form-select {
  @apply w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500;
}

.option-item {
  @apply flex items-center space-x-2;
}

.btn-remove-option {
  @apply text-red-500 hover:text-red-700;
}

.btn-add-option {
  @apply text-blue-500 hover:text-blue-700 text-sm;
}

.form-actions {
  @apply flex justify-end space-x-3 pt-4;
}

.error-message {
  @apply text-red-500 text-sm;
}

.spinner {
  @apply inline-block w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin;
}
</style>
```

### Store Module (Vuex)

```javascript
// app/javascript/dashboard/store/modules/customFields.js
import CustomFieldAPI from '../../api/customFields'
import types from '../mutation-types'

const state = {
  records: [],
  uiFlags: {
    isFetching: false,
    isCreating: false,
    isUpdating: false,
    isDeleting: false
  }
}

const getters = {
  getCustomFields: state => state.records,
  getUIFlags: state => state.uiFlags,
  getCustomFieldById: state => id => {
    return state.records.find(field => field.id === Number(id))
  }
}

const actions = {
  async get({ commit }) {
    commit(types.SET_CUSTOM_FIELD_UI_FLAG, { isFetching: true })
    try {
      const response = await CustomFieldAPI.get()
      commit(types.SET_CUSTOM_FIELDS, response.data)
    } catch (error) {
      console.error('Error fetching custom fields:', error)
      throw error
    } finally {
      commit(types.SET_CUSTOM_FIELD_UI_FLAG, { isFetching: false })
    }
  },

  async createCustomField({ commit }, fieldData) {
    commit(types.SET_CUSTOM_FIELD_UI_FLAG, { isCreating: true })
    try {
      const response = await CustomFieldAPI.create(fieldData)
      commit(types.ADD_CUSTOM_FIELD, response.data)
      return response.data
    } catch (error) {
      console.error('Error creating custom field:', error)
      throw error
    } finally {
      commit(types.SET_CUSTOM_FIELD_UI_FLAG, { isCreating: false })
    }
  },

  async updateCustomField({ commit }, { id, ...fieldData }) {
    commit(types.SET_CUSTOM_FIELD_UI_FLAG, { isUpdating: true })
    try {
      const response = await CustomFieldAPI.update(id, fieldData)
      commit(types.EDIT_CUSTOM_FIELD, response.data)
      return response.data
    } catch (error) {
      console.error('Error updating custom field:', error)
      throw error
    } finally {
      commit(types.SET_CUSTOM_FIELD_UI_FLAG, { isUpdating: false })
    }
  },

  async deleteCustomField({ commit }, id) {
    commit(types.SET_CUSTOM_FIELD_UI_FLAG, { isDeleting: true })
    try {
      await CustomFieldAPI.delete(id)
      commit(types.DELETE_CUSTOM_FIELD, id)
    } catch (error) {
      console.error('Error deleting custom field:', error)
      throw error
    } finally {
      commit(types.SET_CUSTOM_FIELD_UI_FLAG, { isDeleting: false })
    }
  }
}

const mutations = {
  [types.SET_CUSTOM_FIELDS](state, data) {
    state.records = data
  },

  [types.ADD_CUSTOM_FIELD](state, customField) {
    state.records.push(customField)
  },

  [types.EDIT_CUSTOM_FIELD](state, updatedField) {
    const index = state.records.findIndex(field => field.id === updatedField.id)
    if (index !== -1) {
      state.records.splice(index, 1, updatedField)
    }
  },

  [types.DELETE_CUSTOM_FIELD](state, id) {
    const index = state.records.findIndex(field => field.id === id)
    if (index !== -1) {
      state.records.splice(index, 1)
    }
  },

  [types.SET_CUSTOM_FIELD_UI_FLAG](state, uiFlag) {
    state.uiFlags = { ...state.uiFlags, ...uiFlag }
  }
}

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations
}
```

### API Client

```javascript
// app/javascript/dashboard/api/customFields.js
import ApiClient from './ApiClient'

class CustomFieldAPI extends ApiClient {
  constructor() {
    super('custom_fields', { accountScoped: true })
  }

  get() {
    return axios.get(this.url)
  }

  create(fieldData) {
    return axios.post(this.url, { custom_field: fieldData })
  }

  update(id, fieldData) {
    return axios.patch(`${this.url}/${id}`, { custom_field: fieldData })
  }

  delete(id) {
    return axios.delete(`${this.url}/${id}`)
  }
}

export default new CustomFieldAPI()
```

---

## Trabajando con la Base de Datos

### Migraciones Comunes

```ruby
# Agregar columna
class AddStatusToCustomFields < ActiveRecord::Migration[7.1]
  def change
    add_column :custom_fields, :status, :integer, default: 0
    add_index :custom_fields, :status
  end
end

# Cambiar tipo de columna
class ChangeCustomFieldOptionsToJsonb < ActiveRecord::Migration[7.1]
  def up
    change_column :custom_fields, :field_options, :jsonb, using: 'field_options::jsonb'
  end
  
  def down
    change_column :custom_fields, :field_options, :text
  end
end

# Crear tabla de unión
class CreateCustomFieldValues < ActiveRecord::Migration[7.1]
  def change
    create_table :custom_field_values do |t|
      t.references :custom_field, null: false, foreign_key: true
      t.references :contact, null: false, foreign_key: true
      t.text :value
      
      t.timestamps
    end
    
    add_index :custom_field_values, [:custom_field_id, :contact_id], unique: true, name: 'idx_custom_field_values_unique'
  end
end
```

### Queries Optimizadas

```ruby
# Malo: N+1 queries
conversations = Conversation.all
conversations.each do |conv|
  puts conv.contact.name  # Query adicional por conversación
end

# Bueno: Eager loading
conversations = Conversation.includes(:contact).all
conversations.each do |conv|
  puts conv.contact.name  # Sin queries adicionales
end

# Malo: Cargar todos los registros
def active_conversations
  Conversation.where(status: 'open').all
end

# Bueno: Usar paginación
def active_conversations(page: 1, per_page: 25)
  Conversation.where(status: 'open')
              .includes(:contact, :assignee)
              .page(page)
              .per(per_page)
end

# Malo: Queries en loops
contacts.each do |contact|
  contact.conversations.where(status: 'open').count
end

# Bueno: Batch query
contact_ids = contacts.pluck(:id)
open_counts = Conversation.where(contact_id: contact_ids, status: 'open')
                         .group(:contact_id)
                         .count
```

### Seeds para Desarrollo

```ruby
# db/seeds.rb
return unless Rails.env.development?

# Crear cuenta de prueba
account = Account.find_or_create_by!(name: 'Acme Corp') do |acc|
  acc.domain = 'acme.chatwoot.local'
  acc.support_email = 'support@acme.com'
end

# Crear usuario administrador
admin = User.find_or_create_by!(email: 'admin@acme.com') do |user|
  user.password = 'password'
  user.password_confirmation = 'password'
  user.name = 'Admin User'
  user.confirmed_at = Time.current
end

# Asociar usuario con cuenta
AccountUser.find_or_create_by!(
  account: account,
  user: admin,
  role: 'administrator'
)

# Crear inbox de website
inbox = account.inboxes.find_or_create_by!(name: 'Website Chat') do |ib|
  ib.channel_type = 'Channel::WebWidget'
  ib.channel_data = {
    website_url: 'https://acme.com',
    widget_color: '#1f93ff',
    welcome_title: 'Welcome to Acme!',
    welcome_tagline: 'How can we help you today?'
  }
end

# Crear contactos de prueba
10.times do |i|
  contact = account.contacts.find_or_create_by!(email: "customer#{i}@example.com") do |c|
    c.name = "Customer #{i}"
    c.phone_number = "+1555000000#{i}"
  end
  
  # Crear ContactInbox
  contact_inbox = ContactInbox.find_or_create_by!(
    contact: contact,
    inbox: inbox,
    source_id: SecureRandom.uuid
  )
  
  # Crear conversación con algunos mensajes
  conversation = account.conversations.find_or_create_by!(
    contact: contact,
    inbox: inbox,
    contact_inbox: contact_inbox
  ) do |conv|
    conv.status = ['open', 'resolved', 'pending'].sample
    conv.assignee = admin if [true, false].sample
  end
  
  # Crear mensajes
  3.times do |j|
    Message.find_or_create_by!(
      conversation: conversation,
      account: account,
      inbox: inbox,
      content: "This is message #{j} from customer #{i}",
      message_type: 'incoming',
      sender: contact
    )
  end
end

puts "✅ Development seed data created!"
puts "📧 Admin login: admin@acme.com / password"
puts "🏢 Account: #{account.name}"
puts "📞 Inbox: #{inbox.name}"
```

---

## Testing y Calidad de Código

### Tests Backend (RSpec)

```ruby
# spec/models/custom_field_spec.rb
require 'rails_helper'

RSpec.describe CustomField, type: :model do
  let(:account) { create(:account) }
  
  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:field_type) }
    it { should validate_uniqueness_of(:name).scoped_to(:account_id) }
  end
  
  describe 'associations' do
    it { should belong_to(:account) }
  end
  
  describe 'enums' do
    it { should define_enum_for(:field_type).with_values(text: 0, number: 1, date: 2, select: 3) }
  end
  
  describe 'scopes' do
    let!(:active_field) { create(:custom_field, account: account, active: true) }
    let!(:inactive_field) { create(:custom_field, account: account, active: false) }
    
    it 'returns only active fields' do
      expect(CustomField.active).to include(active_field)
      expect(CustomField.active).not_to include(inactive_field)
    end
  end
end

# spec/services/custom_fields/field_builder_spec.rb
require 'rails_helper'

RSpec.describe CustomFields::FieldBuilder do
  let(:account) { create(:account) }
  let(:params) { { name: 'Test Field', field_type: 'text' } }
  let(:service) { described_class.new(account: account, params: params) }
  
  describe '#perform' do
    context 'with valid params' do
      it 'creates a custom field' do
        expect { service.perform }.to change { account.custom_fields.count }.by(1)
      end
      
      it 'returns the created field' do
        field = service.perform
        expect(field).to be_a(CustomField)
        expect(field.name).to eq('Test Field')
        expect(field.field_type).to eq('text')
      end
    end
    
    context 'with invalid params' do
      let(:params) { { name: '', field_type: 'text' } }
      
      it 'raises validation error' do
        expect { service.perform }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
    
    context 'with select field type' do
      let(:params) do
        {
          name: 'Priority',
          field_type: 'select',
          field_options: { options: [{ value: 'High' }, { value: 'Low' }] }
        }
      end
      
      it 'creates field with options' do
        field = service.perform
        expect(field.field_options['options']).to be_present
      end
    end
  end
end

# spec/controllers/api/v1/accounts/custom_fields_controller_spec.rb
require 'rails_helper'

RSpec.describe Api::V1::Accounts::CustomFieldsController, type: :controller do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account, role: 'administrator') }
  
  before do
    sign_in(user)
    Current.account = account
  end
  
  describe 'GET #index' do
    let!(:custom_fields) { create_list(:custom_field, 3, account: account) }
    
    it 'returns all custom fields' do
      get :index, params: { account_id: account.id }
      
      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body).size).to eq(3)
    end
  end
  
  describe 'POST #create' do
    let(:valid_params) do
      {
        account_id: account.id,
        custom_field: {
          name: 'Test Field',
          field_type: 'text'
        }
      }
    end
    
    context 'with valid params' do
      it 'creates a custom field' do
        expect do
          post :create, params: valid_params
        end.to change { account.custom_fields.count }.by(1)
        
        expect(response).to have_http_status(:created)
      end
    end
    
    context 'with invalid params' do
      let(:invalid_params) do
        {
          account_id: account.id,
          custom_field: { name: '' }
        }
      end
      
      it 'returns validation errors' do
        post :create, params: invalid_params
        
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)).to have_key('error')
      end
    end
  end
end
```

### Tests Frontend (Vitest)

```javascript
// spec/javascript/dashboard/components/CustomFieldForm.spec.js
import { mount } from '@vue/test-utils'
import { createStore } from 'vuex'
import CustomFieldForm from '@/dashboard/components/custom-fields/CustomFieldForm.vue'

const createWrapper = (props = {}, storeConfig = {}) => {
  const store = createStore({
    modules: {
      customFields: {
        namespaced: true,
        actions: {
          createCustomField: vi.fn(),
          updateCustomField: vi.fn(),
          ...storeConfig.actions
        }
      }
    }
  })
  
  return mount(CustomFieldForm, {
    props,
    global: {
      plugins: [store],
      mocks: {
        $t: (key) => key
      }
    }
  })
}

describe('CustomFieldForm', () => {
  it('renders create form correctly', () => {
    const wrapper = createWrapper()
    
    expect(wrapper.find('h3').text()).toBe('CUSTOM_FIELDS.CREATE_TITLE')
    expect(wrapper.find('#field-name').exists()).toBe(true)
    expect(wrapper.find('#field-type').exists()).toBe(true)
  })
  
  it('renders edit form with existing data', () => {
    const customField = {
      id: 1,
      name: 'Existing Field',
      field_type: 'text'
    }
    
    const wrapper = createWrapper({ customField })
    
    expect(wrapper.find('h3').text()).toBe('CUSTOM_FIELDS.EDIT_TITLE')
    expect(wrapper.find('#field-name').element.value).toBe('Existing Field')
  })
  
  it('shows options input for select type', async () => {
    const wrapper = createWrapper()
    
    await wrapper.find('#field-type').setValue('select')
    
    expect(wrapper.find('.option-item').exists()).toBe(true)
  })
  
  it('calls createCustomField action on form submit', async () => {
    const createAction = vi.fn().mockResolvedValue({})
    const wrapper = createWrapper({}, {
      actions: { createCustomField: createAction }
    })
    
    await wrapper.find('#field-name').setValue('New Field')
    await wrapper.find('#field-type').setValue('text')
    await wrapper.find('form').trigger('submit.prevent')
    
    expect(createAction).toHaveBeenCalledWith(
      expect.any(Object),
      expect.objectContaining({
        name: 'New Field',
        field_type: 'text'
      })
    )
  })
  
  it('handles validation errors', async () => {
    const createAction = vi.fn().mockRejectedValue({
      response: {
        data: {
          errors: { name: ['Name is required'] }
        }
      }
    })
    
    const wrapper = createWrapper({}, {
      actions: { createCustomField: createAction }
    })
    
    await wrapper.find('form').trigger('submit.prevent')
    await wrapper.vm.$nextTick()
    
    expect(wrapper.find('.error-message').text()).toBe('Name is required')
  })
})

// spec/javascript/dashboard/store/modules/customFields.spec.js
import { actions, mutations, getters } from '@/dashboard/store/modules/customFields'
import CustomFieldAPI from '@/dashboard/api/customFields'

vi.mock('@/dashboard/api/customFields')

describe('customFields store module', () => {
  describe('actions', () => {
    let commit, dispatch
    
    beforeEach(() => {
      commit = vi.fn()
      dispatch = vi.fn()
    })
    
    describe('get', () => {
      it('fetches custom fields successfully', async () => {
        const mockData = [{ id: 1, name: 'Test Field' }]
        CustomFieldAPI.get.mockResolvedValue({ data: mockData })
        
        await actions.get({ commit })
        
        expect(commit).toHaveBeenCalledWith('SET_CUSTOM_FIELD_UI_FLAG', { isFetching: true })
        expect(commit).toHaveBeenCalledWith('SET_CUSTOM_FIELDS', mockData)
        expect(commit).toHaveBeenCalledWith('SET_CUSTOM_FIELD_UI_FLAG', { isFetching: false })
      })
    })
  })
  
  describe('mutations', () => {
    it('SET_CUSTOM_FIELDS updates state', () => {
      const state = { records: [] }
      const fields = [{ id: 1, name: 'Test' }]
      
      mutations.SET_CUSTOM_FIELDS(state, fields)
      
      expect(state.records).toEqual(fields)
    })
  })
  
  describe('getters', () => {
    it('getCustomFieldById returns correct field', () => {
      const state = {
        records: [
          { id: 1, name: 'Field 1' },
          { id: 2, name: 'Field 2' }
        ]
      }
      
      const result = getters.getCustomFieldById(state)(1)
      
      expect(result).toEqual({ id: 1, name: 'Field 1' })
    })
  })
})
```

### Configuración de RuboCop

```yaml
# .rubocop.yml
require:
  - rubocop-rails
  - rubocop-rspec
  - rubocop-performance

AllCops:
  TargetRubyVersion: 3.4
  NewCops: enable
  Exclude:
    - 'db/schema.rb'
    - 'db/migrate/*.rb'
    - 'bin/**/*'
    - 'vendor/**/*'
    - 'node_modules/**/*'

Layout/LineLength:
  Max: 120
  AllowedPatterns: ['(\A|\s)#']

Metrics/BlockLength:
  Exclude:
    - 'spec/**/*.rb'
    - 'config/routes.rb'

Metrics/MethodLength:
  Max: 15
  Exclude:
    - 'db/migrate/*.rb'

Style/Documentation:
  Enabled: false

Rails/HasManyOrHasOneDependent:
  Enabled: true

RSpec/NestedGroups:
  Max: 4

RSpec/ExampleLength:
  Max: 10
```

---

## Debugging y Troubleshooting

### Debugging Backend

```ruby
# Usar byebug para debug
def some_method
  byebug  # Pausa ejecución aquí
  # código...
end

# Logging detallado
Rails.logger.debug "Processing conversation: #{conversation.id}"
Rails.logger.info "User #{user.name} performed action"
Rails.logger.error "Failed to process: #{error.message}"

# Debug en tests
RSpec.describe SomeService do
  it 'processes correctly' do
    service = SomeService.new
    puts service.inspect  # Debug output
    expect(service.perform).to be_truthy
  end
end

# ActiveRecord query debugging
conversation = Conversation.includes(:messages).first
puts conversation.messages.loaded?  # true si ya está cargado

# SQL query logging
ActiveRecord::Base.logger = Logger.new(STDOUT)
```

### Debugging Frontend

```javascript
// Console debugging
console.log('Current state:', this.$store.state)
console.table(this.conversations)

// Vue DevTools
// Install browser extension for Vue debugging

// Debug API calls
const response = await ConversationAPI.get()
console.log('API Response:', response)

// Vuex debugging
export default {
  mutations: {
    SET_CONVERSATIONS(state, conversations) {
      console.log('Setting conversations:', conversations)
      state.records = conversations
    }
  }
}

// Component debugging
export default {
  mounted() {
    console.log('Component mounted with props:', this.$props)
  },
  watch: {
    selectedConversation: {
      handler(newVal, oldVal) {
        console.log('Conversation changed:', { newVal, oldVal })
      },
      deep: true
    }
  }
}
```

### Problemas Comunes y Soluciones

#### 1. Performance Issues

```ruby
# Problema: N+1 queries
conversations.each { |c| puts c.contact.name }

# Solución: Eager loading
conversations = Conversation.includes(:contact)
conversations.each { |c| puts c.contact.name }

# Problema: Memoria con datasets grandes
User.all.each { |user| process(user) }

# Solución: Batch processing
User.find_each(batch_size: 1000) { |user| process(user) }
```

#### 2. WebSocket Issues

```javascript
// Debug WebSocket connections
const cable = createConsumer()
cable.subscriptions.create('ConversationChannel', {
  connected() {
    console.log('WebSocket connected')
  },
  disconnected() {
    console.log('WebSocket disconnected')
  },
  received(data) {
    console.log('Received:', data)
  }
})
```

#### 3. Memory Leaks

```ruby
# Problema: Objetos no liberados
class SomeService
  def initialize
    @large_data = load_large_dataset
  end
end

# Solución: Cleanup explícito
class SomeService
  def perform
    process_data
  ensure
    cleanup_resources
  end
  
  private
  
  def cleanup_resources
    @large_data = nil
    GC.start if Rails.env.development?
  end
end
```

---

## Deployment y DevOps

### Docker para Desarrollo

```dockerfile
# Dockerfile.dev
FROM ruby:3.4.4-alpine

RUN apk add --no-cache \
  build-base \
  postgresql-dev \
  nodejs \
  npm \
  git \
  tzdata

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY package.json pnpm-lock.yaml ./
RUN npm install -g pnpm && pnpm install

COPY . .

EXPOSE 3000

CMD ["foreman", "start", "-f", "Procfile.dev"]
```

```yaml
# docker-compose.dev.yml
version: '3.8'
services:
  postgres:
    image: postgres:13-alpine
    environment:
      POSTGRES_DB: chatwoot_development
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: password
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

  redis:
    image: redis:6-alpine
    ports:
      - "6379:6379"

  app:
    build:
      context: .
      dockerfile: Dockerfile.dev
    ports:
      - "3000:3000"
      - "3035:3035"  # Vite dev server
    volumes:
      - .:/app
      - node_modules:/app/node_modules
    environment:
      DATABASE_URL: postgresql://postgres:password@postgres:5432/chatwoot_development
      REDIS_URL: redis://redis:6379
    depends_on:
      - postgres
      - redis

  sidekiq:
    build:
      context: .
      dockerfile: Dockerfile.dev
    command: bundle exec sidekiq
    volumes:
      - .:/app
    environment:
      DATABASE_URL: postgresql://postgres:password@postgres:5432/chatwoot_development
      REDIS_URL: redis://redis:6379
    depends_on:
      - postgres
      - redis

volumes:
  postgres_data:
  node_modules:
```

### CI/CD con GitHub Actions

```yaml
# .github/workflows/test.yml
name: Test Suite

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

jobs:
  test:
    runs-on: ubuntu-latest
    
    services:
      postgres:
        image: postgres:13
        env:
          POSTGRES_PASSWORD: password
          POSTGRES_DB: chatwoot_test
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 5432:5432
      
      redis:
        image: redis:6
        options: >-
          --health-cmd "redis-cli ping"
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 6379:6379
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Set up Ruby
      uses: ruby/setup-ruby@v1
      with:
        ruby-version: 3.4.4
        bundler-cache: true
    
    - name: Set up Node.js
      uses: actions/setup-node@v3
      with:
        node-version: '23'
        cache: 'npm'
    
    - name: Install dependencies
      run: |
        npm install -g pnpm
        pnpm install
    
    - name: Set up database
      env:
        DATABASE_URL: postgresql://postgres:password@localhost:5432/chatwoot_test
        REDIS_URL: redis://localhost:6379
        RAILS_ENV: test
      run: |
        bundle exec rails db:create
        bundle exec rails db:schema:load
    
    - name: Run RSpec tests
      env:
        DATABASE_URL: postgresql://postgres:password@localhost:5432/chatwoot_test
        REDIS_URL: redis://localhost:6379
        RAILS_ENV: test
      run: bundle exec rspec
    
    - name: Run JavaScript tests
      run: npm test
    
    - name: Run linters
      run: |
        bundle exec rubocop
        npm run eslint
```

### Environment Variables para Production

```bash
# Production .env
RAILS_ENV=production
SECRET_KEY_BASE=your_secret_key_here

# Database
DATABASE_URL=postgresql://user:pass@host:5432/chatwoot_production

# Redis
REDIS_URL=rediss://user:pass@host:6380

# Storage
ACTIVE_STORAGE_SERVICE=amazon
AWS_ACCESS_KEY_ID=your_key
AWS_SECRET_ACCESS_KEY=your_secret
AWS_REGION=us-east-1
AWS_S3_BUCKET_NAME=your-bucket

# Email
SMTP_ADDRESS=smtp.mailgun.org
SMTP_PORT=587
SMTP_USERNAME=your_username
SMTP_PASSWORD=your_password
MAILER_SENDER_EMAIL=support@yourcompany.com

# Domain
FRONTEND_URL=https://yourapp.com
FORCE_SSL=true

# Monitoring
SENTRY_DSN=your_sentry_dsn
NEW_RELIC_LICENSE_KEY=your_newrelic_key

# Security
RACK_TIMEOUT_SERVICE_TIMEOUT=60
```

---

## Contribución y Best Practices

### Git Workflow

```bash
# 1. Sync con upstream
git checkout develop
git fetch upstream
git merge upstream/develop
git push origin develop

# 2. Crear feature branch
git checkout -b feature/custom-fields
git push -u origin feature/custom-fields

# 3. Hacer commits descriptivos
git add .
git commit -m "feat: add custom fields functionality

- Add CustomField model with validations
- Create API endpoints for CRUD operations
- Add Vue.js components for UI
- Include comprehensive tests

Closes #123"

# 4. Push y crear PR
git push origin feature/custom-fields
# Crear Pull Request en GitHub

# 5. Después del merge, cleanup
git checkout develop
git pull upstream develop
git branch -d feature/custom-fields
git push origin --delete feature/custom-fields
```

### Convenciones de Commit

```
type(scope): description

[optional body]

[optional footer]
```

**Types:**
- `feat`: Nueva funcionalidad
- `fix`: Bug fix
- `docs`: Documentación
- `style`: Formateo, espacios en blanco
- `refactor`: Refactoring de código
- `test`: Agregar tests
- `chore`: Tareas de mantenimiento

**Examples:**
```
feat(api): add custom fields endpoint
fix(widget): resolve message display issue
docs(readme): update installation guide
test(conversation): add unit tests for status changes
```

### Code Review Checklist

#### Para el Autor
- [ ] Tests incluidos y pasando
- [ ] Documentación actualizada
- [ ] Migraciones incluidas si es necesario
- [ ] No hay console.log o byebug statements
- [ ] Seguir convenciones del proyecto
- [ ] PR description completa

#### Para el Reviewer
- [ ] Funcionalidad cumple requerimientos
- [ ] Código es legible y mantenible
- [ ] Tests cubren casos edge
- [ ] Performance considerada
- [ ] Seguridad evaluada
- [ ] No hay secrets hardcodeados

### Performance Guidelines

#### Backend
```ruby
# Usar índices apropiados
add_index :conversations, [:account_id, :status, :created_at]

# Eager loading para evitar N+1
Conversation.includes(:contact, :assignee).where(status: 'open')

# Usar counter caches
class Account < ApplicationRecord
  has_many :conversations, counter_cache: true
end

# Paginación obligatoria para listados
def index
  @conversations = current_account.conversations
                                 .includes(:contact)
                                 .page(params[:page])
                                 .per(25)
end

# Background jobs para tareas pesadas
ProcessReportJob.perform_later(report_id)
```

#### Frontend
```javascript
// Lazy loading de components
const ConversationView = () => import('./ConversationView.vue')

// Debounce para búsquedas
import { debounce } from 'lodash'

export default {
  methods: {
    search: debounce(function(query) {
      this.performSearch(query)
    }, 300)
  }
}

// Virtual scrolling para listas grandes
<VirtualList
  :items="conversations"
  :item-height="80"
  height="400px"
/>

// Memoización de computed properties costosos
computed: {
  expensiveCalculation() {
    return this.items.reduce((acc, item) => {
      // cálculo costoso
    }, {})
  }
}
```

### Security Best Practices

```ruby
# Usar strong parameters
def conversation_params
  params.require(:conversation).permit(:status, :priority, custom_attributes: {})
end

# Autorización en todos los endpoints
before_action :authenticate_user!
before_action :set_conversation
before_action :authorize_conversation

# Sanitizar contenido HTML
def sanitized_content
  ActionController::Base.helpers.sanitize(content, tags: %w[b i u])
end

# Rate limiting
class ApplicationController
  include Rack::Attack::Throttle
  
  throttle('api_requests', limit: 100, period: 1.hour) do |req|
    req.ip if req.path.start_with?('/api/')
  end
end

# Validar URLs externas
def valid_webhook_url?(url)
  uri = URI.parse(url)
  uri.is_a?(URI::HTTP) && uri.host.present?
rescue URI::InvalidURIError
  false
end
```

Esta guía proporciona todo lo necesario para que un desarrollador pueda comenzar a trabajar efectivamente en el proyecto Chatwoot, desde la configuración inicial hasta las mejores prácticas de desarrollo y deployment.
