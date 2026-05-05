class WhiteboardsController < ApplicationController
  before_action :set_whiteboard, only: %i[ show destroy ]
  before_action :require_authentication, except: %i[ public_show ]
  before_action :authorize_whiteboard, only: %i[ show destroy ]

  def index
    @whiteboards = current_user.whiteboards.order(created_at: :desc)
    @shared_whiteboards = current_user.shared_whiteboards.order(created_at: :desc)
  end

  def new
    @whiteboard = current_user.whiteboards.new
  end

  def create
    @whiteboard = current_user.whiteboards.new(whiteboard_params)

    if @whiteboard.save
      redirect_to @whiteboard, notice: "Pizarra creada."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @strokes = @whiteboard.whiteboard_strokes.order(:created_at)
  end

  def public_show
    @whiteboard = Whiteboard.find_by!(token: params[:token])
    @strokes = @whiteboard.whiteboard_strokes.order(:created_at)
    render :show
  end

  def destroy
    @whiteboard.destroy
    redirect_to whiteboards_path, notice: "Pizarra eliminada."
  end

  private
    def set_whiteboard
      @whiteboard = Whiteboard.find(params[:id])
    end

    def authorize_whiteboard
      unless @whiteboard.collaborator?(current_user)
        redirect_to whiteboards_path, alert: "No tienes acceso a esta pizarra."
      end
    end

    def whiteboard_params
      params.require(:whiteboard).permit(:name, :width, :height, :background_color)
    end
end
