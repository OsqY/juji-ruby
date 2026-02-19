class HabitsController < ApplicationController
  before_action :set_habit, only: %i[ toggle destroy ]

  def index
    @habits = current_user.habits.order(:created_at)
    @new_habit = current_user.habits.build

    # Define the current week (last 7 days including today)
    @dates = (Date.today - 6.days..Date.today).to_a
  end

  def create
    @habit = current_user.habits.build(habit_params)
    if @habit.save
      redirect_to habits_path, notice: "Hábito creado / Habit created."
    else
      @habits = current_user.habits.order(:created_at)
      @dates = (Date.today - 6.days..Date.today).to_a
      @new_habit = @habit
      render :index, status: :unprocessable_entity
    end
  end

  def toggle
    log_date = Date.parse(params[:date]) rescue Date.today
    log = @habit.habit_logs.find_or_initialize_by(log_date: log_date)
    log.completed = !log.completed
    log.save

    redirect_to habits_path
  end

  def destroy
    @habit.destroy
    redirect_to habits_path, notice: "Hábito eliminado / Habit deleted."
  end

  private

  def set_habit
    @habit = current_user.habits.find(params[:id])
  end

  def habit_params
    params.require(:habit).permit(:name)
  end
end
