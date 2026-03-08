class DailyReportsController < ApplicationController
  before_action :set_daily_report, only: %i[ show edit update destroy toggle_blocker ]

  def index
    load_index_data
  end

  def show
  end

  def new
    @daily_report = current_user.daily_reports.new
  end

  def edit
  end

  def create
    @daily_report = current_user.daily_reports.new(daily_report_params)

    if @daily_report.save
      redirect_to daily_reports_path, notice: "Reporte creado con éxito."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @daily_report.update(daily_report_params)
      redirect_to daily_reports_path, notice: "Reporte actualizado."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @daily_report.destroy
    load_index_data

    respond_to do |format|
      format.turbo_stream do
        flash.now[:notice] = "Reporte eliminado."
        render_daily_reports_content
      end
      format.html { redirect_to daily_reports_path(index_context_params), notice: "Reporte eliminado.", status: :see_other }
    end
  end

  def toggle_blocker
    if @daily_report.blockers.blank?
      load_index_data

      respond_to do |format|
        format.turbo_stream do
          flash.now[:alert] = "Este reporte no tiene bloqueo activo."
          render_daily_reports_content(status: :unprocessable_entity)
        end
        format.html { redirect_back fallback_location: daily_reports_path, alert: "Este reporte no tiene bloqueo activo." }
      end

      return
    end

    resolved = ActiveModel::Type::Boolean.new.cast(params[:resolved])
    @daily_report.update_columns(blockers_resolved: resolved, updated_at: Time.current)

    message = resolved ? "Bloqueo marcado como resuelto." : "Bloqueo marcado como pendiente."
    load_index_data

    respond_to do |format|
      format.turbo_stream do
        flash.now[:notice] = message
        render_daily_reports_content
      end
      format.html { redirect_to daily_reports_path(index_context_params), notice: message }
    end
  end

  private
    def load_index_data
      @view_mode = params[:view].in?(%w[ week month ]) ? params[:view] : "week"
      @reference_date = parse_reference_date
      @selected_worked_by = params[:worked_by].to_s.strip
      @selected_work_title = params[:work_title].to_s.strip

      @worked_by_options = current_user.daily_reports
        .where.not(worked_by: [ nil, "" ])
        .distinct
        .order(:worked_by)
        .pluck(:worked_by)

      scoped_reports = current_user.daily_reports
      if @selected_worked_by.present?
        scoped_reports = scoped_reports.where("LOWER(worked_by) LIKE ?", "%#{@selected_worked_by.downcase}%")
      end
      if @selected_work_title.present?
        scoped_reports = scoped_reports.where("LOWER(work_title) LIKE ?", "%#{@selected_work_title.downcase}%")
      end

      @range_start, @range_end = period_bounds(@reference_date, @view_mode)
      @previous_date = @view_mode == "week" ? (@reference_date - 1.week) : @reference_date.prev_month
      @next_date = @view_mode == "week" ? (@reference_date + 1.week) : @reference_date.next_month

      @daily_reports = scoped_reports.where(report_date: @range_start..@range_end).order(report_date: :desc)
      @reports_by_date = @daily_reports.group_by(&:report_date)
      @calendar_days = calendar_days_for(@range_start, @range_end, @view_mode)
    end

    def render_daily_reports_content(status: :ok)
      render turbo_stream: turbo_stream.replace("daily_reports_content", partial: "daily_reports/content"), status: status
    end

    def parse_reference_date
      return Date.strptime(params[:date], "%Y-%m-%d") if params[:date].present?

      Date.current
    rescue ArgumentError
      Date.current
    end

    def period_bounds(reference_date, mode)
      if mode == "month"
        [ reference_date.beginning_of_month, reference_date.end_of_month ]
      else
        [ reference_date.beginning_of_week, reference_date.end_of_week ]
      end
    end

    def calendar_days_for(range_start, range_end, mode)
      if mode == "month"
        month_grid_start = range_start.beginning_of_week
        month_grid_end = range_end.end_of_week
        (month_grid_start..month_grid_end).to_a
      else
        (range_start..range_end).to_a
      end
    end

    def set_daily_report
      @daily_report = current_user.daily_reports.find(params[:id])
    end

    def daily_report_params
      params.expect(daily_report: [ :report_date, :work_title, :worked_by, :yesterday, :today, :blockers, :additional_details, :photo ])
    end

    def index_context_params
      params.permit(:view, :date, :worked_by, :work_title)
    end
end
