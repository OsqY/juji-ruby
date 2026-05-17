class UserStreak < ApplicationRecord
  belongs_to :user

  validates :streak_type, presence: true, uniqueness: { scope: :user_id }

  STREAK_TYPES = %w[daily_report daily_habit budget_check].freeze

  def self.record_activity!(user, streak_type)
    streak = find_or_initialize_by(user: user, streak_type: streak_type)
    today = Date.current

    if streak.last_activity_date == today
      # Already recorded today, do nothing
      return streak
    elsif streak.last_activity_date == today - 1.day
      # Consecutive day, increment streak
      streak.current_streak += 1
    else
      # Streak broken, restart
      streak.current_streak = 1
    end

    streak.longest_streak = [streak.longest_streak, streak.current_streak].max
    streak.last_activity_date = today
    streak.save!

    # Check for streak achievements
    check_achievements!(user, streak_type, streak.current_streak)

    streak
  end

  def self.check_achievements!(user, streak_type, current_streak)
    milestones = {
      "daily_report" => { 7 => "week_streak", 30 => "month_streak", 100 => "century_streak" },
      "daily_habit" => { 7 => "habit_week", 30 => "habit_month", 365 => "habit_year" },
      "budget_check" => { 7 => "budget_week", 30 => "budget_month" }
    }

    return unless milestones[streak_type]

    milestones[streak_type].each do |days, achievement_type|
      if current_streak == days
        user.user_achievements.find_or_create_by!(achievement_type: "#{streak_type}_#{achievement_type}") do |achievement|
          achievement.title = "Racha de #{days} días"
          achievement.description = "Mantuviste una racha de #{days} días en #{streak_type.humanize}"
          achievement.unlocked_at = Time.current
          achievement.icon = "flame"
        end
      end
    end
  end
end
