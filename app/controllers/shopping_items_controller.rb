class ShoppingItemsController < ApplicationController
  before_action :set_shopping_item, only: %i[ update destroy ]

  def index
    @shopping_items = current_user.shopping_items.order(created_at: :desc)
    @new_item = current_user.shopping_items.build
  end

  def create
    @shopping_item = current_user.shopping_items.build(shopping_item_params)

    if @shopping_item.save
      redirect_to shopping_items_path, notice: "Artículo agregado / Item added."
    else
      @shopping_items = current_user.shopping_items.order(created_at: :desc)
      @new_item = @shopping_item
      render :index, status: :unprocessable_entity
    end
  end

  def update
    @shopping_item.update(bought: !@shopping_item.bought)
    redirect_to shopping_items_path
  end

  def destroy
    @shopping_item.destroy
    redirect_to shopping_items_path, notice: "Eliminado / Deleted."
  end

  private

  def set_shopping_item
    @shopping_item = current_user.shopping_items.find(params[:id])
  end

  def shopping_item_params
    params.require(:shopping_item).permit(:name, :quantity)
  end
end
