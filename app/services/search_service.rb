class SearchService
  # Realiza búsqueda global en múltiples modelos
  def self.perform(query, user, limit: 10)
    return {} if query.blank?

    query = query.strip.downcase
    results = {}

    # Transacciones
    results[:transactions] = user.transactions
      .where("LOWER(description) LIKE ? OR LOWER(category) LIKE ?", "%#{query}%", "%#{query}%")
      .order(date: :desc)
      .limit(limit)

    # Reportes Diarios
    results[:daily_reports] = user.daily_reports
      .where("LOWER(work_title) LIKE ? OR LOWER(yesterday) LIKE ? OR LOWER(today) LIKE ? OR LOWER(blockers) LIKE ? OR LOWER(additional_details) LIKE ?",
             "%#{query}%", "%#{query}%", "%#{query}%", "%#{query}%", "%#{query}%")
      .order(report_date: :desc)
      .limit(limit)

    # Proyectos
    results[:projects] = user.projects
      .where("LOWER(name) LIKE ? OR LOWER(description) LIKE ?", "%#{query}%", "%#{query}%")
      .order(created_at: :desc)
      .limit(limit)

    # Tareas de Proyectos
    results[:project_tasks] = ProjectTask
      .joins(:project)
      .where(projects: { user_id: user.id })
      .where("LOWER(project_tasks.name) LIKE ?", "%#{query}%")
      .order("project_tasks.created_at DESC")
      .limit(limit)

    # Hábitos
    results[:habits] = user.habits
      .where("LOWER(name) LIKE ?", "%#{query}%")
      .order(created_at: :desc)
      .limit(limit)

    # Artículos de Compra
    results[:shopping_items] = user.shopping_items
      .where("LOWER(name) LIKE ? OR LOWER(quantity) LIKE ?", "%#{query}%", "%#{query}%")
      .order(created_at: :desc)
      .limit(limit)

    # Presupuestos
    results[:budgets] = user.budgets
      .where("LOWER(category) LIKE ?", "%#{query}%")
      .order(created_at: :desc)
      .limit(limit)

    # Formularios Anónimos
    results[:anonymous_forms] = user.anonymous_forms
      .where("LOWER(title) LIKE ? OR LOWER(description) LIKE ?", "%#{query}%", "%#{query}%")
      .order(created_at: :desc)
      .limit(limit)

    results
  end

  # Retorna el recuento total de resultados
  def self.count(query, user)
    results = perform(query, user, limit: 1000) # Usar límite alto para contar
    results.sum { |_, records| records.size }
  end

  # Retorna resultados organizados para mostrar
  def self.organized_results(query, user, limit: 10)
    raw_results = perform(query, user, limit: limit)
    
    {
      query: query,
      total_count: raw_results.sum { |_, records| records.size },
      results: raw_results.reject { |_, records| records.empty? }.transform_keys { |k| k.to_s.humanize }
    }
  end
end
