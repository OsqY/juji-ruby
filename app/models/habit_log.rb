class HabitLog < ApplicationRecord
  belongs_to :habit
  validates :log_date, presence: true
  validates :log_date, uniqueness: { scope: :habit_id }
end
