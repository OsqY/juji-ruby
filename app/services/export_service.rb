require "csv"
require "prawn"

class ExportService
  def self.to_csv(user, model_name, filters = {})
    case model_name
    when "transactions"
      export_transactions_csv(user, filters)
    when "reports"
      export_reports_csv(user, filters)
    when "projects"
      export_projects_csv(user, filters)
    when "habits"
      export_habits_csv(user, filters)
    else
      raise ArgumentError, "Unsupported model: #{model_name}"
    end
  end

  def self.to_pdf(user, model_name, filters = {})
    case model_name
    when "transactions"
      export_transactions_pdf(user, filters)
    when "reports"
      export_reports_pdf(user, filters)
    when "projects"
      export_projects_pdf(user, filters)
    when "habits"
      export_habits_pdf(user, filters)
    else
      raise ArgumentError, "Unsupported model: #{model_name}"
    end
  end

  # CSV Exports
  private

  def self.export_transactions_csv(user, filters)
    transactions = filter_transactions(user, filters)
    
    CSV.generate(headers: true) do |csv|
      csv << ["Fecha", "Descripcion", "Categoria", "Monto", "Tipo"]
      
      transactions.each do |t|
        csv << [
          t.date.strftime("%Y-%m-%d"),
          t.description,
          t.category,
          format("%.2f", t.amount),
          t.transaction_type
        ]
      end
    end
  end

  def self.export_reports_csv(user, filters)
    reports = filter_reports(user, filters)
    
    CSV.generate(headers: true) do |csv|
      csv << ["Fecha", "Titulo Trabajo", "Trabajado Por", "Ayer", "Hoy"]
      
      reports.each do |r|
        csv << [
          r.report_date.strftime("%Y-%m-%d"),
          r.work_title.presence || "-",
          r.worked_by.presence || "-",
          r.yesterday.presence || "-",
          r.today.presence || "-"
        ]
      end
    end
  end

  def self.export_projects_csv(user, filters)
    projects = filter_projects(user, filters)
    
    CSV.generate(headers: true) do |csv|
      csv << ["Nombre", "Descripcion", "Fecha Objetivo", "Tareas Totales", "Tareas Completadas", "Progreso"]
      
      projects.each do |p|
        total = p.project_tasks.count
        completed = p.project_tasks.where(completed: true).count
        progress = total > 0 ? (completed.to_f / total * 100).round(1) : 0
        
        csv << [
          p.name,
          p.description.presence || "-",
          p.target_date.present? ? p.target_date.strftime("%Y-%m-%d") : "-",
          total,
          completed,
          "#{progress}%"
        ]
      end
    end
  end

  def self.export_habits_csv(user, filters)
    habits = filter_habits(user, filters)
    
    CSV.generate(headers: true) do |csv|
      csv << ["Habito", "Creado", "Registros Totales", "Completados", "Tasa Cumplimiento"]
      
      habits.each do |h|
        logs = h.habit_logs
        total = logs.count
        completed = logs.where(completed: true).count
        rate = total > 0 ? (completed.to_f / total * 100).round(1) : 0
        
        csv << [
          h.name,
          h.created_at.strftime("%Y-%m-%d"),
          total,
          completed,
          "#{rate}%"
        ]
      end
    end
  end

  # PDF Exports
  def self.export_transactions_pdf(user, filters)
    transactions = filter_transactions(user, filters)
    
    pdf = Prawn::Document.new
    pdf.font_size 14
    pdf.text "Reporte de Transacciones", style: :bold
    
    pdf.font_size 10
    date_range = filter_date_range_text(filters)
    pdf.text "Periodo: #{date_range}"
    pdf.move_down 10
    
    if transactions.any?
      transactions.each do |t|
        pdf.text "Transaccion: #{t.date.strftime('%Y-%m-%d')} - #{t.description}"
        pdf.text "  Categoria: #{t.category} | Monto: L. #{format('%.2f', t.amount)} (#{t.transaction_type})"
        pdf.move_down 5
      end
    else
      pdf.text "Sin transacciones en el periodo"
    end
    
    pdf.move_down 10
    total = transactions.sum(:amount)
    pdf.text "Total: L. #{format('%.2f', total)}", style: :bold
    
    pdf.render
  end

  def self.export_reports_pdf(user, filters)
    reports = filter_reports(user, filters)
    
    pdf = Prawn::Document.new
    pdf.font_size 14
    pdf.text "Reporte de Reportes Diarios", style: :bold
    
    pdf.font_size 10
    date_range = filter_date_range_text(filters)
    pdf.text "Periodo: #{date_range}"
    pdf.move_down 10
    
    if reports.any?
      reports.each do |r|
        pdf.text "Reporte: #{r.report_date.strftime('%Y-%m-%d')} - #{r.work_title}"
        pdf.text "  Trabajado por: #{r.worked_by}"
        if r.yesterday.present?
          summary = r.yesterday.length > 100 ? r.yesterday[0..100] + "..." : r.yesterday
          pdf.text "  Ayer: #{summary}"
        end
        if r.today.present?
          summary = r.today.length > 100 ? r.today[0..100] + "..." : r.today
          pdf.text "  Hoy: #{summary}"
        end
        pdf.move_down 8
      end
    else
      pdf.text "Sin reportes en el periodo"
    end
    
    pdf.move_down 10
    pdf.text "Total reportes: #{reports.count}", style: :bold
    
    pdf.render
  end

  def self.export_projects_pdf(user, filters)
    projects = filter_projects(user, filters)
    
    pdf = Prawn::Document.new
    pdf.font_size 14
    pdf.text "Reporte de Proyectos", style: :bold
    
    pdf.font_size 10
    pdf.move_down 10
    
    if projects.any?
      projects.each do |p|
        total = p.project_tasks.count
        completed = p.project_tasks.where(completed: true).count
        progress = total > 0 ? (completed.to_f / total * 100).round(1) : 0
        
        pdf.text "Proyecto: #{p.name}", style: :bold
        pdf.text "  Descripcion: #{p.description.presence || '-'}"
        pdf.text "  Fecha objetivo: #{p.target_date.present? ? p.target_date.strftime('%Y-%m-%d') : 'Sin definir'}"
        pdf.text "  Progreso: #{progress}% (#{completed}/#{total} tareas)"
        pdf.move_down 8
      end
    else
      pdf.text "Sin proyectos en el periodo"
    end
    
    pdf.move_down 10
    pdf.text "Total proyectos: #{projects.count}", style: :bold
    
    pdf.render
  end

  def self.export_habits_pdf(user, filters)
    habits = filter_habits(user, filters)
    
    pdf = Prawn::Document.new
    pdf.font_size 14
    pdf.text "Reporte de Habitos", style: :bold
    
    pdf.font_size 10
    pdf.move_down 10
    
    if habits.any?
      habits.each do |h|
        logs = h.habit_logs
        total = logs.count
        completed = logs.where(completed: true).count
        rate = total > 0 ? (completed.to_f / total * 100).round(1) : 0
        
        pdf.text "Habito: #{h.name}", style: :bold
        pdf.text "  Registros: #{completed}/#{total} (#{rate}%)"
        pdf.text "  Creado: #{h.created_at.strftime('%Y-%m-%d')}"
        pdf.move_down 8
      end
    else
      pdf.text "Sin habitos"
    end
    
    pdf.move_down 10
    pdf.text "Total habitos: #{habits.count}", style: :bold
    
    pdf.render
  end

  # Helper methods for filtering
  def self.filter_transactions(user, filters)
    transactions = user.transactions.all
    
    if filters[:date_from].present?
      transactions = transactions.where("date >= ?", filters[:date_from])
    end
    
    if filters[:date_to].present?
      transactions = transactions.where("date <= ?", filters[:date_to])
    end
    
    if filters[:category].present?
      transactions = transactions.where(category: filters[:category])
    end
    
    transactions.order(date: :desc)
  end

  def self.filter_reports(user, filters)
    reports = user.daily_reports.all
    
    if filters[:date_from].present?
      reports = reports.where("report_date >= ?", filters[:date_from])
    end
    
    if filters[:date_to].present?
      reports = reports.where("report_date <= ?", filters[:date_to])
    end
    
    reports.order(report_date: :desc)
  end

  def self.filter_projects(user, filters)
    projects = user.projects.all
    
    if filters[:date_from].present?
      projects = projects.where("target_date >= ?", filters[:date_from])
    end
    
    if filters[:date_to].present?
      projects = projects.where("target_date <= ?", filters[:date_to])
    end
    
    projects.order(created_at: :desc)
  end

  def self.filter_habits(user, filters)
    user.habits.order(name: :asc)
  end

  def self.filter_date_range_text(filters)
    from = filters[:date_from].present? ? filters[:date_from].strftime("%Y-%m-%d") : "Inicio"
    to = filters[:date_to].present? ? filters[:date_to].strftime("%Y-%m-%d") : "Hoy"
    "#{from} a #{to}"
  end
end
