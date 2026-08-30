class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :daily_reports, dependent: :destroy
  has_many :transactions, dependent: :destroy
  has_many :people, dependent: :destroy
  has_many :budgets, dependent: :destroy
  has_many :projects, dependent: :destroy
  has_many :habits, dependent: :destroy
  has_many :shopping_items, dependent: :destroy
  has_many :anonymous_forms, dependent: :destroy
  has_many :anonymous_form_responses, dependent: :nullify
  has_many :notifications, dependent: :destroy
  has_many :whiteboards, dependent: :destroy
  has_many :whiteboard_collaborators, dependent: :destroy
  has_many :shared_whiteboards, through: :whiteboard_collaborators, source: :whiteboard

  has_many :chat_rooms, foreign_key: :owner_id, dependent: :destroy
  has_many :chat_room_members, dependent: :destroy
  has_many :joined_chat_rooms, through: :chat_room_members, source: :chat_room
  has_many :messages, dependent: :nullify

  has_many :friendships_requested, class_name: "Friendship", foreign_key: :requester_id, dependent: :destroy
  has_many :friendships_received, class_name: "Friendship", foreign_key: :addressee_id, dependent: :destroy

  has_many :monthly_goals, dependent: :destroy
  has_many :user_streaks, dependent: :destroy
  has_many :user_achievements, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  before_validation :generate_invite_token

  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, presence: true, length: { minimum: 6 }, if: -> { new_record? || password.present? }
  validates :display_name, length: { maximum: 50 }, allow_blank: true
  validates :invite_token, presence: true, uniqueness: true

  def display_name_or_email
    display_name.presence || email_address
  end

  def friends
    requested_friends = friendships_requested.active.includes(:addressee).map(&:addressee)
    received_friends = friendships_received.active.includes(:requester).map(&:requester)
    (requested_friends + received_friends).uniq
  end

  def friend_with?(other_user)
    return false unless other_user
    friendships_requested.exists?(addressee: other_user, status: :accepted) ||
      friendships_received.exists?(requester: other_user, status: :accepted)
  end

  def friendship_with(other_user)
    friendships_requested.find_by(addressee: other_user) ||
      friendships_received.find_by(requester: other_user)
  end

  def pending_friend_requests
    friendships_received.pending
  end

  def dm_with(other_user)
    my_dm_ids = joined_chat_rooms.where(room_type: ChatRoom.room_types[:direct_message]).pluck(:id)
    ChatRoom.where(id: my_dm_ids)
            .joins(:chat_room_members)
            .where(chat_room_members: { user_id: other_user.id })
            .first
  end

  def invite_url
    Rails.application.routes.url_helpers.user_invite_url(token: invite_token)
  end

  def ensure_invite_token!
    return if invite_token.present?
    update_column(:invite_token, SecureRandom.urlsafe_base64(16))
  end

  private
    def generate_invite_token
      self.invite_token ||= SecureRandom.urlsafe_base64(16)
    end
end
