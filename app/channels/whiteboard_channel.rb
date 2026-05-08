class WhiteboardChannel < ApplicationCable::Channel
  def subscribed
    @whiteboard = Whiteboard.find_by(id: params[:whiteboard_id])

    if @whiteboard && (@whiteboard.collaborator?(current_user) || public_access?)
      stream_for @whiteboard
      transmit_existing_strokes
    else
      reject
    end
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  def draw(data)
    return unless @whiteboard
    return unless can_draw?

    stroke = @whiteboard.whiteboard_strokes.create!(
      user: current_user,
      stroke_data: data["stroke"]
    )

    broadcast_to(@whiteboard, {
      type: "stroke",
      stroke: stroke.stroke_data,
      user_id: stroke.user_id,
      stroke_id: stroke.id,
      client_id: data["client_id"]
    })
  end

  def clear
    return unless @whiteboard
    return unless can_clear?

    @whiteboard.whiteboard_strokes.destroy_all
    broadcast_to(@whiteboard, { type: "clear" })
  end

  def undo(data)
    return unless @whiteboard
    return unless can_draw?

    scope = @whiteboard.whiteboard_strokes
    if current_user
      scope = scope.where(user: current_user)
    else
      scope = scope.where(user_id: nil)
    end

    stroke = scope.order(created_at: :desc).first
    if stroke
      stroke.destroy
      broadcast_to(@whiteboard, { type: "undo", stroke_id: stroke.id })
    end
  end

  def delete(data)
    return unless @whiteboard
    return unless can_draw?

    stroke_ids = Array(data["stroke_ids"]).compact.map(&:to_i)
    return if stroke_ids.empty?

    # Only allow deleting own strokes (or any stroke for board owner)
    scope = @whiteboard.whiteboard_strokes.where(id: stroke_ids)
    unless can_clear?
      if current_user
        scope = scope.where(user: current_user)
      else
        scope = scope.where(user_id: nil)
      end
    end

    destroyed_ids = scope.pluck(:id)
    scope.destroy_all

    broadcast_to(@whiteboard, { type: "delete", stroke_ids: destroyed_ids })
  end

  private
    def transmit_existing_strokes
      strokes = @whiteboard.whiteboard_strokes.order(:created_at).map do |s|
        {
          stroke: s.stroke_data,
          user_id: s.user_id,
          stroke_id: s.id
        }
      end

      transmit({ type: "init", strokes: strokes })
    end

    def public_access?
      params[:token].present? && @whiteboard.token == params[:token]
    end

    def can_draw?
      current_user ? @whiteboard.collaborator?(current_user) : public_access?
    end

    def can_clear?
      current_user ? @whiteboard.user_id == current_user.id : false
    end
end
