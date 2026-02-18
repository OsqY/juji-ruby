module ApplicationHelper
  def format_as_list(text)
    return "" if text.blank?

    lines = text.split("\n").map(&:strip).reject(&:blank?)
    return simple_format(text) if lines.size <= 1

    content_tag(:ul, class: "editorial-list") do
      lines.each do |line|
        # Remove leading dashes or bullets if present
        clean_line = line.sub(/^[-\*\•]\s*/, "")
        concat content_tag(:li, clean_line)
      end
    end
  end
end
