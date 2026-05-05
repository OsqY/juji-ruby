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
    return unless @whiteboard.collaborator?(current_user) || public_access?

    stroke = @whiteboard.whiteboard_strokes.create!(
      user: current_user,
      stroke_data: data["stroke"]
    )

    broadcast_to(@whiteboard, {
      type: "stroke",
      stroke: stroke.stroke_data,
      user_id: stroke.user_id,
      stroke_id: stroke.id
    })
  end

  def clear
    return unless @whiteboard
    return unless @whiteboard.user_id == current_user.id

    @whiteboard.whiteboard_strokes.destroy_all
    broadcast_to(@whiteboard, { type: "clear" })
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
end
