class AnalyticsController < ApplicationController
  before_action :authenticate_user!
  
  def index
    @spending_monthly = AnalyticsService.spending_by_month(current_user, months: 12)
    @spending_category = AnalyticsService.spending_by_category(current_user, limit: 5)
    @habit_completion = AnalyticsService.habit_completion_rate(current_user, months: 12)
    @project_status = AnalyticsService.project_status(current_user)
    @alerts_trend = AnalyticsService.alerts_trend(current_user, months: 12)
    @weekly_balance = AnalyticsService.weekly_balance(current_user, weeks: 12)
    @project_progress = AnalyticsService.project_progress(current_user)
    @expense_summary = AnalyticsService.expense_summary(current_user, days: 30)
  end

  def data
    metric = params[:metric]
    period = params[:period] || 12
    
    data = case metric
           when "spending_monthly"
             AnalyticsService.spending_by_month(current_user, months: period.to_i)
           when "spending_category"
             AnalyticsService.spending_by_category(current_user, limit: 5)
           when "habit_completion"
             AnalyticsService.habit_completion_rate(current_user, months: period.to_i)
           when "alerts_trend"
             AnalyticsService.alerts_trend(current_user, months: period.to_i)
           when "weekly_balance"
             AnalyticsService.weekly_balance(current_user, weeks: period.to_i)
           when "project_progress"
             AnalyticsService.project_progress(current_user)
           else
             {}
           end
    
    render json: data
  end
end
