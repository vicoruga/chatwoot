# Guía de Configuración de Desarrollo - Chatwoot

Esta guía te ayudará a configurar un entorno de desarrollo local para nuestro fork de Chatwoot.

## Prerrequisitos

### Software Requerido

- **Ruby**: 3.4.4 (recomendado via rbenv)
- **Node.js**: 18.x o superior
- **PostgreSQL**: 16.x con extensión pgvector
- **Redis**: 6.x o superior
- **Git**: Para control de versiones

### Instalación de Dependencias

#### Ruby con rbenv

```bash
# Instalar rbenv si no lo tienes
curl -fsSL https://github.com/rbenv/rbenv-installer/raw/HEAD/bin/rbenv-installer | bash

# Instalar Ruby 3.4.4
rbenv install 3.4.4
rbenv global 3.4.4

# Verificar instalación
ruby --version
```

#### PostgreSQL con pgvector

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install postgresql postgresql-contrib postgresql-16-pgvector

# Iniciar servicio
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

#### Redis

```bash
# Ubuntu/Debian
sudo apt install redis-server

# Iniciar servicio
sudo systemctl start redis-server
sudo systemctl enable redis-server
```

## Configuración del Proyecto

### 1. Clonar el Repositorio

```bash
git clone https://github.com/vicoruga/chatwoot.git
cd chatwoot

# Configurar upstream
git remote add upstream https://github.com/chatwoot/chatwoot.git
```

### 2. Cambiar a la Rama de Desarrollo

```bash
git checkout custom/main
```

### 3. Instalar Dependencias Ruby

```bash
# Instalar bundler
gem install bundler

# Instalar gemas
bundle install
```

### 4. Instalar Dependencias Node.js

```bash
# Usando pnpm (recomendado)
npm install -g pnpm
pnpm install

# O usando npm
# npm install
```

### 5. Configuración de Base de Datos

#### Crear Usuario PostgreSQL

```bash
sudo -u postgres psql
```

```sql
-- Crear usuario para Chatwoot
CREATE USER chatwoot WITH PASSWORD 'tu_password_seguro';
ALTER USER chatwoot CREATEDB;
ALTER USER chatwoot WITH SUPERUSER;

-- Habilitar extensión pgvector
CREATE EXTENSION IF NOT EXISTS vector;

-- Salir
\q
```

#### Configurar Variables de Entorno

```bash
# Copiar ejemplo de configuración
cp .env.example .env
```

Editar `.env` con la configuración local:

```bash
# Database
POSTGRES_HOST=localhost
POSTGRES_USERNAME=chatwoot
POSTGRES_PASSWORD=tu_password_seguro
POSTGRES_DATABASE=chatwoot_dev

# Redis
REDIS_URL=redis://localhost:6379

# Frontend
FRONTEND_URL=http://localhost:3000

# Habilitar registro de cuentas para desarrollo
ENABLE_ACCOUNT_SIGNUP=true

# Secret key (generar uno nuevo)
SECRET_KEY_BASE=$(rails secret)
```

### 6. Configurar Base de Datos

```bash
# Crear base de datos
rails db:create

# Ejecutar migraciones
rails db:migrate

# Cargar datos semilla (opcional)
rails db:seed
```

### 7. Compilar Assets

```bash
# Compilar assets de frontend
bin/vite build

# O en modo desarrollo con watch
bin/vite dev
```

## Ejecutar la Aplicación

### Servidor de Desarrollo

```bash
# Terminal 1: Rails server
rails server

# Terminal 2: Vite dev server (para desarrollo frontend)
bin/vite dev

# Terminal 3: Sidekiq (para jobs en background)
bundle exec sidekiq
```

### Acceso a la Aplicación

- **Frontend**: http://localhost:3000
- **API**: http://localhost:3000/api/v1/

## Problemas Comunes y Soluciones

### Error en Migración ActsAsTaggableOn

**Síntoma**: Error durante `rails db:migrate` relacionado con ActsAsTaggableOn::Taggable::Cache

**Solución**: Ya está aplicada en nuestro fork. El archivo `db/migrate/20231211010807_add_cached_labels_list.rb` tiene la línea problemática comentada.

### Página en Blanco Después del Login

**Síntomas**:
- Login exitoso pero página en blanco
- URL incorrecta después del redirect

**Solución**:
1. Verificar `FRONTEND_URL=http://localhost:3000` en `.env`
2. Asegurar que `ENABLE_ACCOUNT_SIGNUP=true` esté configurado
3. Limpiar cache del navegador

### Problemas de Conexión a PostgreSQL

**Síntomas**:
- Error de conexión a base de datos
- `PG::ConnectionBad`

**Solución**:
1. Verificar que PostgreSQL esté ejecutándose: `sudo systemctl status postgresql`
2. Confirmar credenciales en `.env`
3. Verificar que el usuario tenga permisos: `psql -U chatwoot -h localhost -d postgres`

### Problemas con Redis

**Síntomas**:
- Sidekiq no puede conectar
- Jobs no se procesan

**Solución**:
1. Verificar que Redis esté ejecutándose: `redis-cli ping`
2. Confirmar URL en `.env`: `REDIS_URL=redis://localhost:6379`

### Assets no se Cargan

**Síntomas**:
- Estilos no se aplican
- JavaScript no funciona

**Solución**:
1. Ejecutar `bin/vite build`
2. Reiniciar el servidor Rails
3. Para desarrollo: usar `bin/vite dev` en terminal separado

## Comandos Útiles

### Base de Datos

```bash
# Reset completo de base de datos
rails db:drop db:create db:migrate db:seed

# Solo ejecutar migraciones nuevas
rails db:migrate

# Rollback última migración
rails db:rollback

# Verificar estado de migraciones
rails db:migrate:status
```

### Desarrollo

```bash
# Ejecutar tests
bundle exec rspec

# Linter de Ruby
bundle exec rubocop

# Linter de JavaScript/TypeScript
pnpm lint

# Consola Rails
rails console

# Ver logs
tail -f log/development.log
```

### Git

```bash
# Actualizar desde upstream
git fetch upstream
git checkout develop
git merge upstream/develop

# Aplicar cambios a custom/main
git checkout custom/main
git rebase develop
```

## Configuración del Editor

### VS Code

Instalar extensiones recomendadas:
- Ruby LSP
- Vetur (para Vue.js)
- GitLens
- Prettier

### Configuración de Prettier (.prettierrc)

```json
{
  "semi": true,
  "singleQuote": true,
  "tabWidth": 2,
  "trailingComma": "es5"
}
```

## Próximos Pasos

Después de tener el entorno configurado:

1. **Explorar el código**: Familiarízate con la estructura del proyecto
2. **Hacer pruebas**: Crea una cuenta de prueba y explora las funcionalidades
3. **Leer documentación**: Revisa las guías en `/docs`
4. **Configurar herramientas**: Instala extensiones del editor y herramientas de desarrollo

## Recursos Adicionales

- [Documentación oficial de Chatwoot](https://www.chatwoot.com/docs/)
- [Guía de contribución upstream](https://github.com/chatwoot/chatwoot/blob/develop/CONTRIBUTING.md)
- [Ruby on Rails Guides](https://guides.rubyonrails.org/)
- [Vue.js Documentation](https://vuejs.org/guide/)

---

*Última actualización: 2025-09-01*
