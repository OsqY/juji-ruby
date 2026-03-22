class SearchController < ApplicationController
  def index
    @query = params[:q]&.strip
    @results = {}
    @total_count = 0

    if @query.present?
      @results = SearchService.perform(@query, current_user, limit: 10)
      
      # Apply filters if provided
      @results = apply_filters(@results) if params[:type].present? || params[:from_date].present? || params[:to_date].present?
      
      @total_count = @results.sum { |_, records| records.size }
    end
  end

  def results
    query = params[:q]&.strip
    
    if query.blank?
      render json: { results: {}, total_count: 0 }
      return
    end

    results = SearchService.perform(query, current_user, limit: 8) # Menos resultados para autocomplete

    # Organizar para JSON
    formatted_results = {}
    results.each do |model_name, records|
      formatted_results[model_name.to_s] = records.map { |record| format_result(record, model_name) }
    end

    render json: {
      query: query,
      results: formatted_results,
      total_count: results.sum { |_, records| records.size }
    }
  end

  private

  def apply_filters(results)
    filtered = {}
    type_filter = params[:type]&.to_sym
    from_date = parse_date_param(params[:from_date])
    to_date = parse_date_param(params[:to_date])

    results.each do |model_name, records|
      # Apply type filter
      if type_filter.present? && model_name != type_filter
        next
      end

      # Apply date filter if applicable
      filtered_records = records.filter do |record|
        date_field = get_date_field(record, model_name)
        next true unless date_field

        if from_date && to_date
          date_field.between?(from_date, to_date)
        elsif from_date
          date_field >= from_date
        elsif to_date
          date_field <= to_date
        else
          true
        end
      end

      filtered[model_name] = filtered_records if filtered_records.any?
    end

    filtered
  end

  def parse_date_param(value)
    return nil if value.blank?

    Date.iso8601(value)
  rescue ArgumentError
    nil
  end

  def get_date_field(record, model_name)
    case model_name
    when :transactions
      record.date
    when :daily_reports
      record.report_date
    when :project_tasks, :habits, :shopping_items
      record.created_at&.to_date
    when :projects, :budgets, :anonymous_forms
      record.created_at&.to_date
    else
      nil
    end
  end

  def format_result(record, model_name)
    case model_name
    when :transactions
      {
        id: record.id,
        title: record.description,
        subtitle: "#{record.transaction_type.humanize} - L. #{number_with_precision(record.amount, precision: 2)}",
        url: transaction_path(record),
        type: 'transaction',
        icon: record.income? ? "IN" : "OUT",
        category: record.category
      }
    when :daily_reports
      {
        id: record.id,
        title: record.work_title,
        subtitle: "Reporte - #{record.report_date.strftime('%d/%m/%Y')}",
        url: daily_report_path(record),
        type: 'report',
        icon: "RPT",
        date: record.report_date
      }
    when :projects
      {
        id: record.id,
        title: record.name,
        subtitle: record.description&.truncate(50) || "Proyecto",
        url: project_path(record),
        type: 'project',
        icon: "PRJ"
      }
    when :project_tasks
      {
        id: record.id,
        title: record.name,
        subtitle: "Tarea - #{record.project.name}",
        url: project_project_task_path(record.project, record),
        type: 'task',
        icon: record.completed? ? "DONE" : "TODO",
        completed: record.completed?
      }
    when :habits
      {
        id: record.id,
        title: record.name,
        subtitle: "Hábito",
        url: habit_path(record),
        type: 'habit',
        icon: "HBT"
      }
    when :shopping_items
      {
        id: record.id,
        title: record.name,
        subtitle: "Cantidad: #{record.quantity}",
        url: shopping_item_path(record),
        type: 'shopping',
        icon: "SHP"
      }
    when :budgets
      {
        id: record.id,
        title: record.category,
        subtitle: "Presupuesto - L. #{number_with_precision(record.monthly_limit, precision: 2)}",
        url: budget_path(record),
        type: 'budget',
        icon: "BDG"
      }
    when :anonymous_forms
      {
        id: record.id,
        title: record.title,
        subtitle: record.description&.truncate(50) || "Formulario",
        url: anonymous_form_path(record),
        type: 'form',
        icon: "FRM"
      }
    else
      {
        id: record.id,
        title: record.to_s,
        type: model_name.to_s
      }
    end
  end
end
