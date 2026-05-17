class WhiteboardStroke < ApplicationRecord
  belongs_to :whiteboard
  belongs_to :user, optional: true

  validates :stroke_data, presence: true
  validate :stroke_data_size_within_limit

  MAX_STROKE_DATA_SIZE = 1.megabyte

  private

    def stroke_data_size_within_limit
      return unless stroke_data.present?

      data_size = stroke_data.to_json.bytesize
      if data_size > MAX_STROKE_DATA_SIZE
        errors.add(:stroke_data, "es demasiado grande (máximo #{MAX_STROKE_DATA_SIZE / 1.kilobyte} KB)")
      end
    end
end
