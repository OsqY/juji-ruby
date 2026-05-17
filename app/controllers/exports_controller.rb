class ExportsController < ApplicationController
  def create
    permitted = params.permit(:model, :format, :date_from, :date_to, :category, :status)
    model_name = permitted[:model]
    format = permitted[:format] || "csv"
    
    # Build filters from params
    filters = build_filters(permitted)
    
    # Validate model
    unless valid_model?(model_name)
      render json: { error: "Invalid model" }, status: :unprocessable_entity
      return
    end
    
    begin
      if format == "csv"
        export_csv(current_user, model_name, filters)
      elsif format == "pdf"
        export_pdf(current_user, model_name, filters)
      else
        render json: { error: "Unsupported format" }, status: :unprocessable_entity
      end
    rescue => e
      Rails.logger.error("Export failed: #{e.message}")
      render json: { error: "Export failed. Please try again." }, status: :unprocessable_entity
    end
  end

  private

  def export_csv(user, model_name, filters)
    data = ExportService.to_csv(user, model_name, filters)
    filename = "#{model_name}_#{Time.zone.today}.csv"
    
    send_data(
      data,
      type: "text/csv",
      disposition: "attachment",
      filename: filename
    )
  end

  def export_pdf(user, model_name, filters)
    data = ExportService.to_pdf(user, model_name, filters)
    filename = "#{model_name}_#{Time.zone.today}.pdf"
    
    send_data(
      data,
      type: "application/pdf",
      disposition: "attachment",
      filename: filename
    )
  end

  def valid_model?(model_name)
    %w[transactions reports projects habits budgets shopping_items].include?(model_name)
  end

  def build_filters(params)
    filters = {}
    
    if params[:date_from].present?
      filters[:date_from] = parse_date_safely(params[:date_from])
    end
    
    if params[:date_to].present?
      filters[:date_to] = parse_date_safely(params[:date_to])
    end
    
    if params[:category].present?
      filters[:category] = params[:category]
    end
    
    if params[:status].present?
      filters[:status] = params[:status]
    end
    
    filters
  end

  def parse_date_safely(value)
    return nil if value.blank?
    Date.parse(value)
  rescue ArgumentError
    nil
  end
end
