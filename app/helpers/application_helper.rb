module ApplicationHelper
  def format_php_currency(amount)
    number_to_currency(amount, unit: "₱", precision: 2, delimiter: ",", separator: ".")
  end
end
