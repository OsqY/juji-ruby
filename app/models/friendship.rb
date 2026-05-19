class Friendship < ApplicationRecord
  belongs_to :requester, class_name: "User"
  belongs_to :addressee, class_name: "User"

  enum :status, { pending: 0, accepted: 1, rejected: 2, blocked: 3 }

  before_validation :generate_invitation_token, on: :create
  before_validation :set_friendship_pair

  after_create_commit :notify_addressee, if: :pending?

  validates :requester_id, uniqueness: { scope: :addressee_id, message: "ya existe una solicitud" }
  validates :friendship_pair, presence: true, uniqueness: true
  validates :invitation_token, presence: true, uniqueness: true
  validate :cannot_friend_self
  validate :reverse_friendship_does_not_exist

  scope :active, -> { where(status: :accepted) }
  scope :pending_for, ->(user) { where(addressee: user, status: :pending) }
  scope :requested_by, ->(user) { where(requester: user, status: :pending) }

  def accept!
    update!(status: :accepted, accepted_at: Time.current)
  end

  def reject!
    update!(status: :rejected)
  end

  def block!
    update!(status: :blocked)
  end

  def invitation_url
    Rails.application.routes.url_helpers.friend_invitation_url(token: invitation_token)
  end

  def other_user(user)
    requester_id == user.id ? addressee : requester
  end

  private
    def generate_invitation_token
      self.invitation_token ||= SecureRandom.urlsafe_base64(16)
    end

    def cannot_friend_self
      errors.add(:addressee, "no puedes ser amigo de ti mismo") if requester_id == addressee_id
    end

    def reverse_friendship_does_not_exist
      return unless requester_id.present? && addressee_id.present?

      if Friendship.exists?(requester_id: addressee_id, addressee_id: requester_id)
        errors.add(:base, "Ya existe una solicitud de amistad entre estos usuarios")
      end
    end

    def set_friendship_pair
      return unless requester_id.present? && addressee_id.present?
      self.friendship_pair = "#{[requester_id, addressee_id].min}:#{[requester_id, addressee_id].max}"
    end

    def notify_addressee
      PushNotificationService.send_to_user(
        addressee,
        title: "Nueva solicitud de amistad",
        body: "#{requester.display_name_or_email} quiere conectar contigo",
        data: { type: "friend_request", url: "/friends/pending" }
      )
    end
end
