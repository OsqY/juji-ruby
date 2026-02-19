class DailyReportsController < ApplicationController
  before_action :set_daily_report, only: %i[ show edit update destroy ]

  def index
    @daily_reports = current_user.daily_reports.order(report_date: :desc)
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
    redirect_to daily_reports_path, notice: "Reporte eliminado.", status: :see_other
  end

  private
    def set_daily_report
      @daily_report = current_user.daily_reports.find(params[:id])
    end

    def daily_report_params
      params.require(:daily_report).permit(:report_date, :yesterday, :today, :blockers, :additional_details, :photo)
    end
end
