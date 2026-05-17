class Whiteboard < ApplicationRecord
  belongs_to :user
  has_many :whiteboard_strokes, dependent: :destroy
  has_many :whiteboard_collaborators, dependent: :destroy
  has_many :collaborators, through: :whiteboard_collaborators, source: :user

  before_validation :generate_token, on: :create

  validates :name, presence: true
  validates :token, presence: true, uniqueness: true
  validates :width, :height, numericality: { greater_than: 0 }
  validates :background_color, format: { with: /\A#[0-9A-Fa-f]{6}\z/, message: "debe ser un color hexadecimal válido" }, allow_blank: true

  def to_param
    id.to_s
  end

  def add_collaborator(user)
    whiteboard_collaborators.find_or_create_by(user: user)
  end

  def collaborator?(user)
    return false unless user
    user_id == user.id || whiteboard_collaborators.exists?(user: user)
  end

  private
    def generate_token
      self.token ||= SecureRandom.urlsafe_base64(12)
    end
end
