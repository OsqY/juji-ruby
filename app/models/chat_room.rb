class ChatRoom < ApplicationRecord
  belongs_to :owner, class_name: "User"
  has_many :chat_room_members, dependent: :destroy
  has_many :members, through: :chat_room_members, source: :user
  has_many :messages, dependent: :destroy

  before_validation :generate_token, on: :create

  enum :room_type, { open: 0, private_code: 1, channel: 2, direct_message: 3 }

  validates :name, presence: true, length: { maximum: 100 }
  validates :token, presence: true, uniqueness: true
  validates :capacity, numericality: { greater_than: 0, only_integer: true }, allow_nil: true

  scope :active, -> { where(archived_at: nil) }
  scope :public_rooms, -> { active.where(room_type: [room_types[:open], room_types[:channel]]) }
  scope :searchable, -> { active.where(room_type: [room_types[:open], room_types[:channel]]) }
  scope :excluding_direct_messages, -> { where.not(room_type: room_types[:direct_message]) }

  def to_param
    id.to_s
  end

  def member?(user)
    return false unless user
    chat_room_members.exists?(user: user)
  end

  def admin_or_owner?(user)
    return false unless user
    chat_room_members.exists?(user: user, role: [ChatRoomMember.roles[:owner], ChatRoomMember.roles[:admin]])
  end

  def owner?(user)
    return false unless user
    owner_id == user.id
  end

  def can_join?(user)
    return false unless user
    return false if archived_at.present?
    return false if member?(user)
    return false if capacity.present? && chat_room_members.count >= capacity
    true
  end

  def can_speak?(user)
    return false unless user
    return false unless member?(user)
    return true unless channel?
    admin_or_owner?(user)
  end

  def add_member(user, role: :member)
    chat_room_members.create!(user: user, role: role, joined_at: Time.current)
  end

  def remove_member(user)
    chat_room_members.find_by(user: user)&.destroy
  end

  def member_count
    chat_room_members.count
  end

  def full?
    capacity.present? && member_count >= capacity
  end

  def invitation_url
    Rails.application.routes.url_helpers.public_chat_room_path(token: token)
  end

  private
    def generate_token
      self.token ||= SecureRandom.urlsafe_base64(12)
    end
end
