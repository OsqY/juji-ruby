# Configuración del sistema de alertas

# Usar zona horaria configurada en config/application.rb
# En lugar de Date.today de servidor, los checks usan Time.zone.today
# que respeta la configuración de Rails

module AlertsConfig
  # Umbrales de alertas (pueden ser customizables por usuario en el futuro)
  DAYS_WITHOUT_REPORT = 3
  DAYS_PROJECT_NO_PROGRESS = 7
end
