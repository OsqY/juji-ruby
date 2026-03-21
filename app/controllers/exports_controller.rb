class ExportsController < ApplicationController
  def create
    model_name = params[:model]
    format = params[:format] || "csv"
    
    # Build filters from params
    filters = build_filters(params)
    
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
      render json: { error: e.message }, status: :unprocessable_entity
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
    %w[transactions reports projects habits].include?(model_name)
  end

  def build_filters(params)
    filters = {}
    
    if params[:date_from].present?
      filters[:date_from] = Date.parse(params[:date_from])
    end
    
    if params[:date_to].present?
      filters[:date_to] = Date.parse(params[:date_to])
    end
    
    if params[:category].present?
      filters[:category] = params[:category]
    end
    
    if params[:status].present?
      filters[:status] = params[:status]
    end
    
    filters
  end
end
