# Custom Assets Directory

Este directorio contiene los assets personalizados para el branding de la instalación Chatwoot.

## Archivos Requeridos

### Logos
- `logo.svg` - Logo principal para modo claro
- `logo_dark.svg` - Logo para modo oscuro  
- `favicon.svg` - Favicon/icono (512x512px recomendado)

### Especificaciones

| Archivo | Formato | Dimensiones | Uso |
|---------|---------|-------------|-----|
| logo.svg | SVG | ~200px ancho | Dashboard, login, emails |
| logo_dark.svg | SVG | ~200px ancho | Dashboard modo oscuro |
| favicon.svg | SVG/PNG | 512x512px | Favicon del navegador |

## Comandos Útiles

```bash
# Copiar logos desde otro directorio
cp /path/to/your/logo.svg ./logo.svg
cp /path/to/your/logo-dark.svg ./logo_dark.svg
cp /path/to/your/favicon.svg ./favicon.svg

# Descargar desde URL
wget https://your-domain.com/logo.svg -O logo.svg

# Verificar permisos
chmod 644 *.svg

# Verificar accesibilidad (desde el root del proyecto)
curl -I http://localhost:3000/custom-assets/logo.svg
```

## Configuración

Los paths de estos archivos están configurados en:
- `/config/initializers/custom_branding.rb`
- Panel de admin: `/super_admin/installation_configs`

## Notas

- Los archivos SVG son recomendados por su escalabilidad
- Asegurar que los archivos tengan permisos de lectura (644)
- Después de agregar/cambiar archivos, limpiar cache: `GlobalConfig.clear_cache`
