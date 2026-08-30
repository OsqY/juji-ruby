class Person < ApplicationRecord
  belongs_to :user
  has_many :expense_shares, dependent: :destroy

  before_validation :set_normalized_name

  validates :name, presence: true, length: { maximum: 80 }
  validates :normalized_name, presence: true

  def self.normalize_name(name)
    name.to_s.squish.downcase
  end

  private
    def set_normalized_name
      self.name = name.to_s.squish
      self.normalized_name = self.class.normalize_name(name)
    end
end
