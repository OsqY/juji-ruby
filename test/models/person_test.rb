require "test_helper"

class PersonTest < ActiveSupport::TestCase
  test "normalizes names and keeps uniqueness within each account" do
    first = users(:one).people.create!(name: "  Ana   María ")

    assert_equal "Ana María", first.name
    assert_equal "ana maría", first.normalized_name
    assert_raises(ActiveRecord::RecordNotUnique) { users(:one).people.create!(name: "ANA MARÍA") }
    assert users(:two).people.create!(name: "Ana María").persisted?
  end
end
