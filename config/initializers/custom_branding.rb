# frozen_string_literal: true

# Custom Branding Configuration
# Este initializer habilita las características de branding que están restringidas
# a la versión premium de Chatwoot, permitiendo personalización completa del branding

Rails.application.config.to_prepare do
  # Características de branding a habilitar para todas las cuentas
  custom_features = ['disable_branding']

  # Habilitar características de branding para todas las cuentas existentes
  Account.find_each do |account|
    features_to_enable = custom_features.reject { |feature| account.feature_enabled?(feature) }

    if features_to_enable.any?
      Rails.logger.info "Habilitando características custom para cuenta #{account.id}: #{features_to_enable.join(', ')}"
      account.enable_features!(*features_to_enable)
    end
  end

  # Configuraciones de branding personalizadas
  # Estas se pueden modificar a través del panel de super admin en /super_admin/installation_configs
  # IMPORTANTE: Solo se aplican si las configuraciones no existen previamente
  custom_branding_configs = {
    'INSTALLATION_NAME' => 'Comunichat Chat',
    'BRAND_NAME' => 'Comunichat',
    'LOGO' => '/custom-assets/logo.svg',
    'LOGO_DARK' => '/custom-assets/logo_dark.svg',
    'LOGO_THUMBNAIL' => '/custom-assets/favicon.svg',
    'BRAND_URL' => 'https://www.comunichat.com',
    'WIDGET_BRAND_URL' => 'https://www.comunichat.com',
    'TERMS_URL' => 'https://www.comunichat.com/terminos',
    'PRIVACY_URL' => 'https://www.comunichat.com/privacidad',
    'DISPLAY_MANIFEST' => false  # Desactivar metadatos de Chatwoot
  }

  # Crear o actualizar configuraciones de branding solo si no existen
  custom_branding_configs.each do |name, default_value|
    existing_config = InstallationConfig.find_by(name: name)

    if existing_config.nil?
      Rails.logger.info "Creando configuración de branding: #{name}"
      InstallationConfig.create!(
        name: name,
        value: default_value,
        locked: false  # Permitir edición desde el panel de admin
      )
    elsif existing_config.locked?
      # Si existe pero está bloqueada, desbloqueamos para permitir edición
      Rails.logger.info "Desbloqueando configuración de branding: #{name}"
      existing_config.update!(locked: false)
    end
  end

  Rails.logger.info 'Custom branding configuration loaded successfully'
end

# Hook para nuevas cuentas que se creen
Rails.application.config.after_initialize do
  # Interceptar la creación de nuevas cuentas para aplicar características custom
  Account.class_eval do
    after_create :enable_custom_branding_features

    private

    def enable_custom_branding_features
      enable_features!('disable_branding')
      Rails.logger.info "Características de branding custom habilitadas para nueva cuenta #{id}"
    end
  end
end
