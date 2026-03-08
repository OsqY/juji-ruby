class ShoppingItemsController < ApplicationController
  before_action :set_shopping_item, only: %i[ update destroy ]

  def index
    load_index_data
  end

  def create
    @shopping_item = current_user.shopping_items.build(shopping_item_params)

    if @shopping_item.save
      load_index_data

      respond_to do |format|
        format.turbo_stream do
          flash.now[:notice] = "Artículo agregado / Item added."
          render_shopping_content
        end
        format.html { redirect_to shopping_items_path, notice: "Artículo agregado / Item added." }
      end
    else
      load_index_data(new_item: @shopping_item)

      respond_to do |format|
        format.turbo_stream do
          flash.now[:alert] = @shopping_item.errors.full_messages.to_sentence.presence || "No se pudo agregar el artículo."
          render_shopping_content(status: :unprocessable_entity)
        end
        format.html { render :index, status: :unprocessable_entity }
      end
    end
  end

  def update
    @shopping_item.update(bought: !@shopping_item.bought)
    load_index_data

    respond_to do |format|
      format.turbo_stream { render_shopping_content }
      format.html { redirect_to shopping_items_path }
    end
  end

  def destroy
    @shopping_item.destroy
    load_index_data

    respond_to do |format|
      format.turbo_stream do
        flash.now[:notice] = "Eliminado / Deleted."
        render_shopping_content
      end
      format.html { redirect_to shopping_items_path, notice: "Eliminado / Deleted." }
    end
  end

  private

  def load_index_data(new_item: nil)
    @shopping_items = current_user.shopping_items.order(created_at: :desc)
    @new_item = new_item || current_user.shopping_items.build
  end

  def render_shopping_content(status: :ok)
    render turbo_stream: turbo_stream.replace("shopping_items_content", partial: "shopping_items/content"), status: status
  end

  def set_shopping_item
    @shopping_item = current_user.shopping_items.find(params[:id])
  end

  def shopping_item_params
    params.require(:shopping_item).permit(:name, :quantity)
  end
end
