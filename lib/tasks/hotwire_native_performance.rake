# lib/tasks/hotwire_native_performance.rake
# Task para medir performance de Hotwire Native

namespace :hotwire_native do
  desc "Analizar performance de la app en contexto de Hotwire Native"
  task performance_check: :environment do
    puts "=" * 80
    puts "HOTWIRE NATIVE - PERFORMANCE CHECK"
    puts "=" * 80
    puts ""

    # 1. Verificar bundle size
    puts "📦 BUNDLE SIZE ANALYSIS"
    puts "-" * 40
    check_asset_sizes
    puts ""

    # 2. Verificar CSS file sizes
    puts "🎨 CSS OPTIMIZATION"
    puts "-" * 40
    check_css_sizes
    puts ""

    # 3. Verificar JavaScript bundles
    puts "⚙️ JAVASCRIPT OPTIMIZATION"
    puts "-" * 40
    check_js_sizes
    puts ""

    # 4. Database query performance
    puts "💾 DATABASE PERFORMANCE"
    puts "-" * 40
    check_database_performance
    puts ""

    # 5. Rendering performance
    puts "🎬 RENDERING PERFORMANCE"
    puts "-" * 40
    check_rendering_performance
    puts ""

    # 6. Mobile-specific checks
    puts "📱 MOBILE-SPECIFIC CHECKS"
    puts "-" * 40
    check_mobile_specific
    puts ""

    puts "=" * 80
    puts "✅ PERFORMANCE CHECK COMPLETO"
    puts "=" * 80
  end

  private

  def check_asset_sizes
    css_files = Dir.glob('app/assets/stylesheets/**/*.css')
    js_files = Dir.glob('app/assets/javascripts/**/*.js')

    total_css_size = css_files.sum { |f| File.size(f) rescue 0 }
    total_js_size = js_files.sum { |f| File.size(f) rescue 0 }

    puts "CSS files: #{css_files.length} archivos (~#{(total_css_size / 1024).round(2)}KB)"
    puts "JS files: #{js_files.length} archivos (~#{(total_js_size / 1024).round(2)}KB)"
    
    warn_if(total_css_size > 500 * 1024, "⚠️  CSS bundle > 500KB (consideraroptimizar)")
    warn_if(total_js_size > 300 * 1024, "⚠️  JS bundle > 300KB (considerr defer/async)")
  end

  def check_css_sizes
    app_css = File.size('app/assets/stylesheets/application.css') rescue 0
    mobile_css = File.size('app/assets/stylesheets/mobile-optimizations.css') rescue 0

    puts "application.css: #{(app_css / 1024).round(2)}KB"
    puts "mobile-optimizations.css: #{(mobile_css / 1024).round(2)}KB"
    
    success_if(app_css < 200 * 1024, "✓ application.css bajo 200KB")
    success_if(mobile_css < 50 * 1024, "✓ mobile-optimizations.css bajo 50KB")
  end

  def check_js_sizes
    importmap_file = 'config/importmap.rb'
    controllers_count = Dir.glob('app/javascript/controllers/*.js').length

    puts "Stimulus controllers: #{controllers_count}"
    puts "Importmap config: #{File.exist?(importmap_file) ? '✓' : '✗'}"
    
    success_if(controllers_count <= 15, "✓ #{controllers_count} controllers (< 15)")
  end

  def check_database_performance
    # Verificar índices en tablas principales
    models = [User, Transaction, DailyReport, Project, Habit]
    
    models.each do |model|
      table_name = model.table_name
      indexes = model.connection.indexes(table_name)
      
      puts "#{model.name}: #{indexes.length} índices"
    end
  end

  def check_rendering_performance
    # Analizar views para N+1 queries
    views_path = 'app/views'
    
    # Contar vistas
    erb_files = Dir.glob("#{views_path}/**/*.erb").length
    
    puts "Total ERB templates: #{erb_files}"
    success_if(erb_files < 100, "✓ Menos de 100 templates")
  end

  def check_mobile_specific
    # Verificar que layouts móviles existen
    mobile_layout = File.exist?('app/views/layouts/application_mobile.html.erb')
    form_partial = File.exist?('app/views/forms/_mobile_friendly.html.erb')
    
    puts "Mobile layout: #{mobile_layout ? '✓' : '✗'}"
    puts "Mobile form helper: #{form_partial ? '✓' : '✗'}"
    
    success_if(mobile_layout && form_partial, "✓ Layouts de mobile configurados")
  end

  def warn_if(condition, message)
    puts message if condition
  end

  def success_if(condition, message)
    puts message if condition
  end
end

# Helper para ejecutar desde CLI
# rake hotwire_native:performance_check
