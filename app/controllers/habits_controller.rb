class HabitsController < ApplicationController
  before_action :set_habit, only: %i[ toggle destroy ]

  def index
    load_index_data
  end

  def create
    @habit = current_user.habits.build(habit_params)

    if @habit.save
      load_index_data

      respond_to do |format|
        format.turbo_stream do
          flash.now[:notice] = "Hábito creado / Habit created."
          render_habits_content
        end
        format.html { redirect_to habits_path, notice: "Hábito creado / Habit created." }
      end
    else
      load_index_data(new_habit: @habit)

      respond_to do |format|
        format.turbo_stream do
          flash.now[:alert] = @habit.errors.full_messages.to_sentence.presence || "No se pudo crear el hábito."
          render_habits_content(status: :unprocessable_entity)
        end
        format.html { render :index, status: :unprocessable_entity }
      end
    end
  end

  def toggle
    log_date = Date.parse(params[:date]) rescue Date.today
    log = @habit.habit_logs.find_or_initialize_by(log_date: log_date)
    log.completed = !log.completed
    log.save

    if log.completed
      UserStreak.record_activity!(current_user, "daily_habit")
      UserAchievement.check_first_time_achievements!(current_user)
    end

    load_index_data

    respond_to do |format|
      format.turbo_stream { render_habits_content }
      format.html { redirect_to habits_path }
    end
  end

  def destroy
    @habit.destroy
    load_index_data

    respond_to do |format|
      format.turbo_stream do
        flash.now[:notice] = "Hábito eliminado / Habit deleted."
        render_habits_content
      end
      format.html { redirect_to habits_path, notice: "Hábito eliminado / Habit deleted." }
    end
  end

  private

  def load_index_data(new_habit: nil)
    @habits = current_user.habits.order(:created_at)
    @new_habit = new_habit || current_user.habits.build
    @dates = (Date.today - 6.days..Date.today).to_a
  end

  def render_habits_content(status: :ok)
    render turbo_stream: turbo_stream.replace("habits_content", partial: "habits/content"), status: status
  end

  def set_habit
    @habit = current_user.habits.find(params[:id])
  end

  def habit_params
    params.require(:habit).permit(:name)
  end
end
