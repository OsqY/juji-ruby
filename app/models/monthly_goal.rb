class MonthlyGoal < ApplicationRecord
  belongs_to :user

  enum :status, { active: 0, completed: 1, failed: 2 }
  enum :goal_type, {
    savings: "savings",
    expense_limit: "expense_limit",
    habit_streak: "habit_streak",
    project_completion: "project_completion",
    report_consistency: "report_consistency"
  }

  validates :title, presence: true
  validates :target_value, presence: true, numericality: { greater_than: 0 }
  validates :month, presence: true
  validates :goal_type, presence: true
  validates :category, presence: true, if: -> { expense_limit? || savings? }

  scope :for_month, ->(date) { where(month: date.beginning_of_month) }
  scope :current, -> { for_month(Date.current) }
  scope :active_goals, -> { where(status: :active) }

  def progress_percentage
    return 0 if target_value.to_f.zero?
    [(current_value.to_f / target_value.to_f * 100).round(1), 100].min
  end

  def check_completion!
    return unless active?

    calculated = calculate_current_value
    self.current_value = calculated

    if calculated >= target_value
      complete!
    else
      save!
    end
  end

  def complete!
    update!(status: :completed)
    user.user_achievements.create!(
      achievement_type: "goal_completed",
      title: "Meta completada: #{title}",
      description: "Alcanzaste tu meta de #{goal_type} para #{month.strftime('%B %Y')}",
      unlocked_at: Time.current,
      icon: "trophy"
    )
  end

  private

  def calculate_current_value
    case goal_type
    when "savings"
      month_range = month.beginning_of_month..month.end_of_month
      income = user.transactions.where(date: month_range, transaction_type: :income).sum(:amount)
      expenses = user.transactions.where(date: month_range, transaction_type: :expense).sum(:amount)
      income - expenses
    when "expense_limit"
      month_range = month.beginning_of_month..month.end_of_month
      user.transactions.where(date: month_range, transaction_type: :expense, category: category).sum(:amount)
    when "habit_streak"
      user.user_streaks.find_by(streak_type: "daily_habit")&.current_streak || 0
    when "project_completion"
      user.projects.includes(:project_tasks).count { |p| p.project_tasks.any? && p.project_tasks.all?(&:completed) }
    when "report_consistency"
      month_range = month.beginning_of_month..month.end_of_month
      user.daily_reports.where(report_date: month_range).count
    else
      current_value
    end
  end
end
