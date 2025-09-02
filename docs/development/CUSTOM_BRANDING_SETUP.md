# Guía de Configuración de Branding Personalizado

## 🎯 Resumen

El sistema de branding personalizado está implementado y funcionando. Esta guía explica cómo personalizar completamente la apariencia de tu instalación Chatwoot.

## ✅ Estado Actual

- ✅ **Característica `disable_branding` habilitada** para todas las cuentas
- ✅ **Configuraciones de branding desbloqueadas** para edición
- ✅ **Initializer personalizado funcionando** correctamente
- ✅ **Cache configurado** y limpiándose automáticamente

## 🎨 Configuraciones Disponibles

### Configuraciones Actuales
```
INSTALLATION_NAME   : MiEmpresa Chat
BRAND_NAME          : MiEmpresa  
BRAND_URL           : https://www.miempresa.com
WIDGET_BRAND_URL    : https://www.miempresa.com
TERMS_URL           : https://www.miempresa.com/terminos
PRIVACY_URL         : https://www.miempresa.com/privacidad
LOGO                : /custom-assets/logo.svg
LOGO_DARK           : /custom-assets/logo_dark.svg
LOGO_THUMBNAIL      : /custom-assets/favicon.svg
DISPLAY_MANIFEST    : false
```

## 📁 Estructura de Assets

```
public/
└── custom-assets/          # Directorio para logos personalizados
    ├── logo.svg            # Logo principal (modo claro)
    ├── logo_dark.svg       # Logo para modo oscuro  
    ├── favicon.svg         # Favicon (512x512px recomendado)
    └── README.md           # Documentación de assets
```

## 🖼️ Preparación de Logos

### Especificaciones Recomendadas

1. **Logo Principal (`logo.svg`)**
   - Formato: SVG (escalable)
   - Dimensiones: Ancho máximo 200px, altura flexible
   - Uso: Dashboard, páginas de login, emails

2. **Logo Modo Oscuro (`logo_dark.svg`)**
   - Formato: SVG
   - Dimensiones: Iguales al logo principal
   - Colores: Optimizado para fondos oscuros

3. **Favicon (`favicon.svg`)**
   - Formato: SVG o PNG
   - Dimensiones: 512x512px (cuadrado)
   - Uso: Pestaña del navegador, bookmarks

### Comandos para Agregar Logos

```bash
# Navegar al directorio de assets
cd /home/mocertec/dev/chatwoot/public/custom-assets

# Opción 1: Copiar logos existentes
cp /path/to/your/logo.svg ./logo.svg
cp /path/to/your/logo-dark.svg ./logo_dark.svg 
cp /path/to/your/favicon.svg ./favicon.svg

# Opción 2: Descargar logos desde URL
wget https://your-domain.com/assets/logo.svg -O logo.svg
wget https://your-domain.com/assets/logo-dark.svg -O logo_dark.svg
wget https://your-domain.com/assets/favicon.svg -O favicon.svg

# Verificar archivos
ls -la /home/mocertec/dev/chatwoot/public/custom-assets/
```

## ⚙️ Métodos de Configuración

### 1. Via Rails Console (Recomendado para pruebas)

```ruby
# Conectarse al Rails console
rails console

# Actualizar configuraciones individuales
config = InstallationConfig.find_by(name: 'INSTALLATION_NAME')
config.update!(value: 'Tu Empresa Chat')

# Actualizar múltiples configuraciones
custom_configs = {
  'INSTALLATION_NAME' => 'Tu Empresa Chat',
  'BRAND_NAME' => 'Tu Empresa',
  'BRAND_URL' => 'https://www.tuempresa.com'
}

custom_configs.each do |name, value|
  InstallationConfig.find_by(name: name)&.update!(value: value)
end

# Limpiar cache
GlobalConfig.clear_cache
```

### 2. Via Panel de Administración

1. Acceder a: `http://your-domain.com/super_admin/installation_configs`
2. Buscar las configuraciones de branding
3. Editar valores directamente
4. Guardar cambios

### 3. Via Initializer (Para valores por defecto)

Editar `/config/initializers/custom_branding.rb` y modificar el hash `custom_branding_configs`.

## 🔄 Aplicar Cambios

### Desarrollo
```bash
# Reiniciar servidor Rails
rails server

# O recargar initializers
rails runner "Rails.application.reload_config_files!"
```

### Producción
```bash
# Reiniciar aplicación
sudo systemctl restart chatwoot-web
sudo systemctl restart chatwoot-worker

# O si usas Docker
docker-compose restart web
docker-compose restart worker
```

## 🧪 Verificación

### Verificar Configuraciones
```ruby
# En Rails console
GlobalConfig.get('INSTALLATION_NAME', 'BRAND_NAME', 'LOGO')

# Verificar que disable_branding está habilitado
Account.first.feature_enabled?('disable_branding')
```

### Verificar Assets
```bash
# Verificar que los logos están accesibles
curl -I http://localhost:3000/custom-assets/logo.svg
curl -I http://localhost:3000/custom-assets/logo_dark.svg
curl -I http://localhost:3000/custom-assets/favicon.svg
```

### Verificar en Browser
1. **Dashboard**: Verificar logo en la barra superior
2. **Widget**: Verificar que no aparece "Powered by Chatwoot"
3. **Login**: Verificar logo en página de autenticación
4. **Favicon**: Verificar icono en pestaña del navegador

## 🚀 Siguientes Pasos

### Opcional: CSS Personalizado
Agregar estilos personalizados via `DASHBOARD_SCRIPTS`:

```ruby
InstallationConfig.find_by(name: 'DASHBOARD_SCRIPTS')&.update!(
  value: '<style>
    /* Estilos personalizados aquí */
    .your-custom-styles { }
  </style>'
)
```

### Opcional: Más Características Premium
Habilitar otras características premium editando el initializer:

```ruby
custom_features = [
  'disable_branding',
  'audit_logs',      # Logs de auditoría
  'custom_roles',    # Roles personalizados  
  'sla'             # Acuerdos de nivel de servicio
]
```

## ⚠️ Notas Importantes

1. **Backups**: Hacer backup de configuraciones antes de cambios importantes
2. **Actualizaciones**: El initializer sobrevive a actualizaciones de Chatwoot
3. **Performance**: Los SVGs son más eficientes que PNG/JPG para logos
4. **Cache**: Cambios en configuraciones requieren limpiar cache (`GlobalConfig.clear_cache`)

## 🐛 Troubleshooting

### Logos no aparecen
```bash
# Verificar permisos
chmod 644 /home/mocertec/dev/chatwoot/public/custom-assets/*

# Verificar que los archivos existen
ls -la /home/mocertec/dev/chatwoot/public/custom-assets/
```

### Configuraciones no se aplican
```ruby
# En Rails console
GlobalConfig.clear_cache
Rails.application.reload_config_files!
```

### Revertir a configuración original
```ruby
# Restaurar configuraciones de Chatwoot originales
InstallationConfig.find_by(name: 'BRAND_NAME')&.update!(value: 'Chatwoot')
InstallationConfig.find_by(name: 'LOGO')&.update!(value: '/brand-assets/logo.svg')
GlobalConfig.clear_cache
```

## 📞 Contacto

Para soporte adicional, revisar:
- `/docs/development/CUSTOM_BRANDING_ANALYSIS.md` - Análisis técnico completo
- `/config/initializers/custom_branding.rb` - Configuración actual
