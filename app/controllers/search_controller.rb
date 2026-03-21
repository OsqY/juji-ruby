class SearchController < ApplicationController
  def index
    @query = params[:q]&.strip
    @results = {}
    @total_count = 0

    if @query.present?
      @results = SearchService.perform(@query, current_user, limit: 10)
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
      formatted_results[model_name.to_s.humanize] = records.map { |record| format_result(record, model_name) }
    end

    render json: {
      query: query,
      results: formatted_results,
      total_count: results.sum { |_, records| records.size }
    }
  end

  private

  def format_result(record, model_name)
    case model_name
    when :transactions
      {
        id: record.id,
        title: record.description,
        subtitle: "#{record.transaction_type.humanize} - L. #{number_with_precision(record.amount, precision: 2)}",
        url: transaction_path(record),
        type: 'transaction',
        icon: record.income? ? '💰' : '💸',
        category: record.category
      }
    when :daily_reports
      {
        id: record.id,
        title: record.work_title,
        subtitle: "Reporte - #{record.report_date.strftime('%d/%m/%Y')}",
        url: daily_report_path(record),
        type: 'report',
        icon: '📝',
        date: record.report_date
      }
    when :projects
      {
        id: record.id,
        title: record.name,
        subtitle: record.description&.truncate(50) || "Proyecto",
        url: project_path(record),
        type: 'project',
        icon: '📊'
      }
    when :project_tasks
      {
        id: record.id,
        title: record.name,
        subtitle: "Tarea - #{record.project.name}",
        url: project_project_task_path(record.project, record),
        type: 'task',
        icon: record.completed? ? '✅' : '◻️',
        completed: record.completed?
      }
    when :habits
      {
        id: record.id,
        title: record.name,
        subtitle: "Hábito",
        url: habit_path(record),
        type: 'habit',
        icon: '🎯'
      }
    when :shopping_items
      {
        id: record.id,
        title: record.name,
        subtitle: "#{record.quantity} #{record.unit}",
        url: shopping_item_path(record),
        type: 'shopping',
        icon: '🛒'
      }
    when :budgets
      {
        id: record.id,
        title: record.category,
        subtitle: "Presupuesto - L. #{number_with_precision(record.monthly_limit, precision: 2)}",
        url: budget_path(record),
        type: 'budget',
        icon: '💳'
      }
    when :anonymous_forms
      {
        id: record.id,
        title: record.title,
        subtitle: record.description&.truncate(50) || "Formulario",
        url: anonymous_form_path(record),
        type: 'form',
        icon: '📋'
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
