# Análisis del Sistema de Branding en Chatwoot

## Resumen Ejecutivo

El sistema de branding en Chatwoot está dividido en dos partes:
1. **Configuración básica de branding**: Disponible para todas las instalaciones
2. **Características premium de branding**: Restringidas a planes de pago (`disable_branding`)

## Configuraciones de Branding Disponibles

### 1. Configuraciones Base (Siempre Disponibles)

Estas configuraciones están definidas en `/config/installation_config.yml`:

```yaml
# Configuraciones de Branding Base
INSTALLATION_NAME: 'Chatwoot'                    # Nombre de la instalación
LOGO_THUMBNAIL: '/brand-assets/logo_thumbnail.svg' # Favicon (512x512px)
LOGO: '/brand-assets/logo.svg'                   # Logo principal
LOGO_DARK: '/brand-assets/logo_dark.svg'         # Logo para modo oscuro
BRAND_URL: 'https://www.chatwoot.com'            # URL de la marca (emails)
WIDGET_BRAND_URL: 'https://www.chatwoot.com'     # URL de la marca (widget)
BRAND_NAME: 'Chatwoot'                           # Nombre de la marca
TERMS_URL: 'https://www.chatwoot.com/terms'      # URL términos de servicio
PRIVACY_URL: 'https://www.chatwoot.com/privacy'  # URL política de privacidad
DISPLAY_MANIFEST: true                           # Mostrar metadatos de Chatwoot
```

### 2. Característica Premium: `disable_branding`

La característica `disable_branding` permite:
- Ocultar el branding "Powered by Chatwoot" del widget
- Ocultar elementos de marca en portales de ayuda
- Control total sobre la presentación visual

## Arquitectura del Sistema

### Modelos Principales

1. **InstallationConfig** (`app/models/installation_config.rb`)
   - Almacena configuraciones globales
   - Serializa valores en JSONB
   - Maneja cache automático

2. **Account** con `Featurable` (`app/models/concerns/featurable.rb`)
   - Maneja flags de características usando FlagShihTzu
   - Métodos: `feature_enabled?()`, `enable_features!()`, `disable_features!()`

### Servicios Principales

1. **GlobalConfig** (`lib/global_config.rb`)
   - Cache de configuraciones con Redis
   - Fallback a base de datos

2. **GlobalConfigService** (`lib/global_config_service.rb`)
   - Carga configuraciones con valores por defecto
   - Migración desde variables de entorno

### Controladores

Las configuraciones se exponen via:
- `DashboardController`: Dashboard principal
- `WidgetsController`: Widget embebido
- `SuperAdmin::InstallationConfigsController`: Panel de administración

### Frontend

La configuración se expone como:
```javascript
window.globalConfig = {
  BRAND_NAME: "...",
  LOGO: "...",
  LOGO_THUMBNAIL: "...",
  // etc...
}
```

## Restricciones Actuales

### Características Premium

Definidas en `/enterprise/config/premium_features.yml`:
```yaml
- disable_branding  # Desactivar branding de Chatwoot
- audit_logs       # Logs de auditoría
- response_bot     # Bot de respuestas
- sla             # Acuerdos de nivel de servicio
- captain_integration # Integración Captain AI
- custom_roles    # Roles personalizados
```

### Servicio de Reconciliación

`Internal::ReconcilePlanConfigService` se encarga de:
1. Resetear configuraciones premium para cuentas gratuitas
2. Deshabilitar características premium automáticamente
3. Restaurar valores por defecto de branding

## Ubicaciones de Archivos Importantes

### Backend
```
/config/installation_config.yml              # Configuraciones base
/enterprise/config/premium_installation_config.yml # Configuraciones premium
/enterprise/config/premium_features.yml      # Lista de características premium
/app/models/installation_config.rb          # Modelo principal
/app/models/concerns/featurable.rb          # Manejo de características
/lib/global_config.rb                       # Servicio de cache
/app/controllers/dashboard_controller.rb     # Controlador principal
```

### Frontend
```
/app/javascript/dashboard/featureFlags.js    # Flags de características
/app/javascript/shared/components/Branding.vue # Componente de branding
/app/views/layouts/vueapp.html.erb          # Layout principal
```

### Administración
```
/app/controllers/super_admin/installation_configs_controller.rb
/app/dashboards/installation_config_dashboard.rb
```

## Propuesta de Implementación Custom

### Opción 1: Desbloquear Características Existentes

**Ventajas:**
- Reutiliza toda la infraestructura existente
- Mínimo código custom
- Compatible con futuras actualizaciones

**Implementación:**
```ruby
# En un initializer personalizado
# config/initializers/custom_features.rb
Rails.application.config.to_prepare do
  # Habilitar disable_branding para todas las cuentas
  Account.where.not(feature_flags: nil).find_each do |account|
    account.enable_features!('disable_branding') unless account.feature_enabled?('disable_branding')
  end
end
```

### Opción 2: Sistema de Branding Custom Paralelo

**Ventajas:**
- Control total sobre branding
- No depende de características premium
- Fácil personalización

**Implementación:**
1. Crear modelo `CustomBrandingConfig`
2. Crear controlador de administración
3. Modificar layout para usar configuraciones custom
4. Crear interfaz de administración

### Opción 3: Override del Servicio de Reconciliación

**Ventajas:**
- Mantiene compatibilidad
- Evita restricciones de plan

**Implementación:**
```ruby
# Sobrescribir el servicio de reconciliación
class Internal::ReconcilePlanConfigService
  def reconcile_premium_features
    # No hacer nada - mantener características habilitadas
  end
end
```

## Recomendación

**Recomiendo la Opción 1** por las siguientes razones:

1. **Mínimo impacto**: Usa toda la infraestructura existente
2. **Mantenibilidad**: Pocas líneas de código custom
3. **Robustez**: Aprovecha el sistema de cache y validaciones existente
4. **Escalabilidad**: Fácil agregar más características premium más adelante

### Plan de Implementación Recomendado

1. **Fase 1**: Crear initializer para habilitar `disable_branding`
2. **Fase 2**: Crear interfaz de administración para configuraciones de branding
3. **Fase 3**: Agregar configuraciones custom adicionales según necesidades
4. **Fase 4**: Documentar proceso para futuras actualizaciones

### Código de Implementación Inicial

```ruby
# config/initializers/custom_branding.rb
Rails.application.config.to_prepare do
  # Habilitar características de branding custom para todas las cuentas
  custom_features = ['disable_branding']
  
  Account.find_each do |account|
    features_to_enable = custom_features.reject { |feature| account.feature_enabled?(feature) }
    account.enable_features!(*features_to_enable) if features_to_enable.any?
  end
  
  # Asegurar que las configuraciones de branding estén disponibles
  branding_configs = {
    'INSTALLATION_NAME' => 'Tu Empresa',
    'BRAND_NAME' => 'Tu Marca',
    'LOGO' => '/custom-assets/logo.svg',
    'LOGO_DARK' => '/custom-assets/logo-dark.svg',
    'LOGO_THUMBNAIL' => '/custom-assets/favicon.svg'
  }
  
  branding_configs.each do |name, default_value|
    InstallationConfig.find_or_create_by(name: name) do |config|
      config.value = default_value
      config.locked = false  # Permitir edición
    end
  end
end
```

Esta implementación permitirá administrar completamente el branding sin depender de las restricciones de la versión premium.
