class MonthlyGoalsController < ApplicationController
  before_action :set_monthly_goal, only: %i[ edit update destroy check_progress ]

  def index
    @current_goals = current_user.monthly_goals.current.active_goals
    @completed_goals = current_user.monthly_goals.current.where(status: :completed)
    @failed_goals = current_user.monthly_goals.current.where(status: :failed)
    @new_goal = current_user.monthly_goals.new(month: Date.current.beginning_of_month)
  end

  def new
    @monthly_goal = current_user.monthly_goals.new(month: Date.current.beginning_of_month)
  end

  def create
    @monthly_goal = current_user.monthly_goals.new(monthly_goal_params)
    @monthly_goal.month = Date.current.beginning_of_month
    @monthly_goal.status = :active

    if @monthly_goal.save
      redirect_to monthly_goals_path, notice: "Meta creada correctamente."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @monthly_goal.update(monthly_goal_params)
      redirect_to monthly_goals_path, notice: "Meta actualizada."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @monthly_goal.destroy
    redirect_to monthly_goals_path, notice: "Meta eliminada."
  end

  def check_progress
    @monthly_goal.check_completion!
    redirect_to monthly_goals_path, notice: "Progreso actualizado."
  end

  private

  def set_monthly_goal
    @monthly_goal = current_user.monthly_goals.find(params[:id])
  end

  def monthly_goal_params
    params.expect(monthly_goal: [ :title, :description, :goal_type, :target_value, :category ])
  end
end
