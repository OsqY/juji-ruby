class Project < ApplicationRecord
  belongs_to :user
  has_many :project_tasks, dependent: :destroy
  validates :name, presence: true
end
