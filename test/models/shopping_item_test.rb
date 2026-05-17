require "test_helper"

class ShoppingItemTest < ActiveSupport::TestCase
  test "belongs to user" do
    item = shopping_items(:one)
    assert item.user.present?
  end

  test "validates name presence" do
    item = ShoppingItem.new(name: nil)
    assert_not item.valid?
    assert_includes item.errors[:name], "no puede estar en blanco"
  end
end
