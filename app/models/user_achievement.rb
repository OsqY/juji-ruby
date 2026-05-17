class UserAchievement < ApplicationRecord
  belongs_to :user

  validates :achievement_type, presence: true, uniqueness: { scope: :user_id }
  validates :title, presence: true

  scope :recent, -> { order(unlocked_at: :desc) }
  scope :unlocked_this_month, -> { where("unlocked_at >= ?", Date.current.beginning_of_month) }

  def self.unlock!(user, achievement_type, title, description, icon = "star")
    find_or_create_by!(user: user, achievement_type: achievement_type) do |achievement|
      achievement.title = title
      achievement.description = description
      achievement.unlocked_at = Time.current
      achievement.icon = icon
    end
  end

  def self.check_first_time_achievements!(user)
    # First daily report
    if user.daily_reports.count == 1
      unlock!(user, "first_report", "Primer Reporte", "Enviaste tu primer reporte diario", "file-text")
    end

    # First transaction
    if user.transactions.count == 1
      unlock!(user, "first_transaction", "Primera Transacción", "Registraste tu primera transacción", "dollar-sign")
    end

    # First project
    if user.projects.count == 1
      unlock!(user, "first_project", "Primer Proyecto", "Creaste tu primer proyecto", "folder")
    end

    # First habit
    if user.habits.count == 1
      unlock!(user, "first_habit", "Primer Hábito", "Creaste tu primer hábito", "activity")
    end

    # First budget
    if user.budgets.count == 1
      unlock!(user, "first_budget", "Primer Presupuesto", "Creaste tu primer presupuesto", "pie-chart")
    end

    # First friend
    if user.friends.count == 1
      unlock!(user, "first_friend", "Primer Amigo", "Conectaste con tu primer amigo", "users")
    end
  end
end
