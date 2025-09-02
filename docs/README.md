# Documentación Completa del Proyecto Chatwoot

Esta documentación está diseñada para proporcionar a los desarrolladores una comprensión completa de la arquitectura, estructura y procesos de desarrollo de Chatwoot.

## 📋 Documentación Principal

### 🏗️ Arquitectura y Estructura
- **[📖 Arquitectura del Proyecto](architecture/ARQUITECTURA_PROYECTO.md)** - Documentación completa de la arquitectura del sistema, stack tecnológico, modelos de datos y patrones de desarrollo
- **[📊 Diagramas de Base de Datos y Flujos](architecture/DIAGRAMAS_BD_FLUJOS.md)** - Diagramas detallados del ERD, flujos de datos y arquitectura del sistema
- **[👨‍💻 Guía de Desarrollo](development/GUIA_DESARROLLO.md)** - Guía práctica completa para desarrolladores con setup, convenciones, ejemplos y best practices

### 🔧 Desarrollo y Contribución
- **[🔀 Gestión de Fork](development/fork-management-guide.md)** - Mejores prácticas para mantener sincronizado con upstream

## 🚀 Quick Start para Desarrolladores

### 1. Lectura Esencial
1. Comienza con la **[Arquitectura del Proyecto](architecture/ARQUITECTURA_PROYECTO.md)** para entender el sistema completo
2. Revisa los **[Diagramas](architecture/DIAGRAMAS_BD_FLUJOS.md)** para visualizar las relaciones entre componentes
3. Sigue la **[Guía de Desarrollo](development/GUIA_DESARROLLO.md)** para configurar tu entorno

### 2. Setup Rápido
```bash
# 1. Clonar y configurar
git clone https://github.com/TU_USUARIO/chatwoot.git
cd chatwoot
cp .env.example .env

# 2. Instalar dependencias
bundle install
pnpm install

# 3. Configurar base de datos
rails db:setup

# 4. Iniciar desarrollo
foreman start -f Procfile.dev
```

### 3. Estructura de Navegación

#### 🎯 Para Nuevos Desarrolladores
- Arquitectura general → Diagramas de base de datos → Setup de desarrollo

#### 🔨 Para Desarrollo Activo
- Guía de desarrollo → Convenciones de código → Testing

#### 🚀 Para DevOps/Deployment
- Configuración de producción → Docker → CI/CD

## 📚 Contenido Detallado

### Arquitectura del Proyecto
- **Stack Tecnológico**: Ruby on Rails 7.1, Vue.js 3.5, PostgreSQL, Redis
- **Modelos Principales**: Account, User, Conversation, Message, Contact, Inbox
- **Patrones de Desarrollo**: Service Objects, Builder Pattern, Event System
- **Frontend**: Vuex state management, componentes Vue, API clients
- **Backend**: Controllers, Services, Jobs, Policies

### Base de Datos
- **ERD Completo**: Diagrama entidad-relación con todas las tablas
- **Relaciones**: Asociaciones entre modelos principales
- **Índices**: Optimizaciones de performance
- **Migraciones**: Patrones comunes de migración

### Flujos del Sistema
- **Mensajes Entrantes**: Webhook → Builder → Broadcast
- **Mensajes Salientes**: API → Validation → External API
- **Autenticación**: JWT tokens con Devise
- **Autorización**: Políticas con Pundit

### Desarrollo Frontend
- **Componentes Vue**: Estructura, props, eventos
- **Store Management**: Módulos Vuex, actions, mutations
- **API Integration**: Clients HTTP, manejo de errores
- **Testing**: Vitest, Vue Test Utils

### Desarrollo Backend
- **Modelos ActiveRecord**: Validaciones, asociaciones, scopes
- **Controllers**: Autenticación, autorización, respuestas JSON
- **Services**: Lógica de negocio encapsulada
- **Jobs**: Procesamiento en background con Sidekiq

### Testing y Calidad
- **Backend Testing**: RSpec, FactoryBot, mocks
- **Frontend Testing**: Vitest, componentes, store
- **Code Quality**: RuboCop, ESLint, convenciones
- **Performance**: N+1 queries, optimizaciones

### Deployment
- **Docker**: Configuración para desarrollo y producción
- **CI/CD**: GitHub Actions, testing automático
- **Environment**: Variables de entorno, configuraciones
- **Monitoring**: Logs, errores, métricas

## 🛠️ Herramientas de Desarrollo

### Backend
- **Ruby 3.4.4** con Rails 7.1
- **PostgreSQL 13+** para base de datos
- **Redis** para cache y sessions
- **Sidekiq** para background jobs
- **RSpec** para testing

### Frontend
- **Node.js 23** con pnpm
- **Vue.js 3.5** con Composition API
- **Vite** como build tool
- **Vuex 4** para state management
- **Tailwind CSS** para estilos

### DevOps
- **Docker** para contenedores
- **GitHub Actions** para CI/CD
- **Heroku/DigitalOcean** para deployment
- **Sentry** para error tracking

## 🤝 Contribución

### Flujo de Trabajo
1. **Fork** del repositorio principal
2. **Feature branch** desde develop
3. **Commits** siguiendo convenciones
4. **Tests** completos y pasando
5. **Pull Request** con descripción detallada

### Convenciones
- **Commits**: `type(scope): description`
- **Branches**: `feature/description`, `fix/description`
- **Code Style**: RuboCop, ESLint, Prettier
- **Documentation**: Inline comments, README updates

### Review Process
- **Automated**: Tests, linting, security checks
- **Manual**: Code review, functionality testing
- **Merge**: Squash commits, update changelog

## 📞 Soporte

### Documentación Externa
- **[Chatwoot Official Docs](https://www.chatwoot.com/help-center)**
- **[API Documentation](https://www.chatwoot.com/developers/api)**
- **[Rails Guides](https://guides.rubyonrails.org/)**
- **[Vue.js Documentation](https://vuejs.org/guide/)**

### Comunidad
- **[Discord](https://discord.gg/cJXdrwS)** - Chat de la comunidad
- **[GitHub Issues](https://github.com/chatwoot/chatwoot/issues)** - Reportar bugs
- **[GitHub Discussions](https://github.com/chatwoot/chatwoot/discussions)** - Preguntas y discusiones

---

## 📋 Checklist para Nuevos Desarrolladores

- [ ] Leer arquitectura completa del proyecto
- [ ] Configurar entorno de desarrollo local
- [ ] Explorar base de datos y modelos
- [ ] Ejecutar test suite completa
- [ ] Crear primer PR con fix menor
- [ ] Revisar convenciones de código
- [ ] Configurar herramientas de desarrollo

¡Bienvenido al equipo de desarrollo de Chatwoot! 🎉

---

## Historial

### 2025-09-01
- ✅ Creación de documentación completa de arquitectura
- ✅ Adición de diagramas de base de datos y flujos
- ✅ Guía completa de desarrollo con ejemplos prácticos
- ✅ Restructuración completa de la documentación

*Última actualización: 2025-09-01*
