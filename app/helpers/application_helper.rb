module ApplicationHelper
  def format_php_currency(amount)
    formatted = number_to_currency(amount, unit: "₱", precision: 2, delimiter: ",", separator: ".")
    content_tag(:span, formatted, class: "font-mono")
  end
end
