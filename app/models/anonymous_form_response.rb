class AnonymousFormResponse < ApplicationRecord
  include ActionView::RecordIdentifier

  belongs_to :anonymous_form, counter_cache: :responses_count, inverse_of: :responses
  belongs_to :user, optional: true

  after_create_commit :broadcast_realtime_updates

  validate :form_capacity_available, on: :create
  validate :authenticated_user_only_once, on: :create

  private
    def broadcast_realtime_updates
      stream = [ anonymous_form, :responses ]

      broadcast_prepend_to(
        stream,
        target: dom_id(anonymous_form, :responses_list),
        partial: "anonymous_forms/response",
        locals: { response: self, anonymous_form: anonymous_form }
      )

      broadcast_replace_to(
        stream,
        target: dom_id(anonymous_form, :responses_stats),
        partial: "anonymous_forms/response_stats",
        locals: { anonymous_form: anonymous_form.reload }
      )

      broadcast_remove_to(stream, target: dom_id(anonymous_form, :responses_empty))
    end

    def form_capacity_available
      return unless anonymous_form
      return if anonymous_form.responses_count < anonymous_form.response_limit

      errors.add(:base, "Este formulario ya alcanzó su límite de respuestas")
    end

    def authenticated_user_only_once
      return if user_id.blank?
      return unless anonymous_form
      return unless anonymous_form.responses.where(user_id: user_id).exists?

      errors.add(:base, "Ya respondiste este formulario")
    end
end
