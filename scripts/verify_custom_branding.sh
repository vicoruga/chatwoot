#!/bin/bash

# Script de Verificación del Sistema de Branding Personalizado
# Ejecutar desde el directorio raíz de Chatwoot

echo "🎯 VERIFICACIÓN DEL SISTEMA DE BRANDING PERSONALIZADO"
echo "=================================================="

# Verificar directorio y archivos
echo -e "\n📁 Verificando Assets Personalizados:"
if [ -d "public/custom-assets" ]; then
    echo "✅ Directorio custom-assets existe"
    
    for asset in logo.svg logo_dark.svg favicon.svg; do
        if [ -f "public/custom-assets/$asset" ]; then
            size=$(stat -c%s "public/custom-assets/$asset")
            echo "✅ $asset - $size bytes"
        else
            echo "❌ $asset - No encontrado"
        fi
    done
else
    echo "❌ Directorio custom-assets no existe"
fi

# Verificar configuraciones (requiere Rails)
echo -e "\n⚙️  Verificando Configuraciones (Rails Console):"
rails_check=$(cat << 'EOF'
branding_configs = %w[INSTALLATION_NAME BRAND_NAME LOGO LOGO_DARK LOGO_THUMBNAIL BRAND_URL WIDGET_BRAND_URL]
configs = GlobalConfig.get(*branding_configs)

puts "\n🎨 Configuraciones de Branding:"
configs.each { |k, v| puts "  #{k.ljust(20)}: #{v}" }

puts "\n🔒 Estado de Características Premium:"
if Account.any?
  account = Account.first
  premium_features = %w[disable_branding audit_logs sla custom_roles]
  premium_features.each do |feature|
    status = account.feature_enabled?(feature) ? "✅" : "❌"
    puts "  #{feature.ljust(20)}: #{status}"
  end
else
  puts "  No hay cuentas en el sistema"
end

puts "\n📊 Resumen:"
puts "  Total de cuentas: #{Account.count}"
puts "  Branding deshabilitado: #{Account.any? && Account.first.feature_enabled?('disable_branding') ? 'Sí' : 'No'}"
puts "  Configuraciones desbloqueadas: #{InstallationConfig.where(name: branding_configs, locked: false).count}/#{branding_configs.length}"
EOF
)

echo "$rails_check" | rails console 2>/dev/null

echo -e "\n🌐 URLs de Verificación:"
echo "  Dashboard: http://localhost:3000/"
echo "  Super Admin: http://localhost:3000/super_admin/installation_configs"
echo "  Logo: http://localhost:3000/custom-assets/logo.svg"
echo "  Logo Dark: http://localhost:3000/custom-assets/logo_dark.svg"
echo "  Favicon: http://localhost:3000/custom-assets/favicon.svg"

echo -e "\n📋 Próximos Pasos:"
echo "  1. Reemplazar logos de ejemplo con los de tu empresa"
echo "  2. Ajustar configuraciones según necesidades"
echo "  3. Reiniciar servidor Rails para aplicar cambios"
echo "  4. Verificar en navegador que el branding funciona"

echo -e "\n✨ ¡Sistema de Branding Personalizado Configurado!"
