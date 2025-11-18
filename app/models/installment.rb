class Installment < ApplicationRecord
  belongs_to :loan
  has_many :installment_payments, dependent: :destroy
  has_many :payments, through: :installment_payments

  validates :installment_number, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :principal_amount, :total_amount, presence: true, numericality: { greater_than: 0 }
  validates :interest_amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :due_date, presence: true
  validates :status, presence: true, inclusion: { in: %w[pending partial paid overdue] }
  validates :amount_paid, numericality: { greater_than_or_equal_to: 0 }

  # Calculate remaining balance for this installment
  def balance_remaining
    total_amount - amount_paid
  end

  # Check if installment is fully paid
  def paid?
    status == "paid" || balance_remaining <= 0.01 # Allow small rounding differences
  end

  # Check if installment is overdue
  def overdue?
    !paid? && due_date < Date.today
  end

  # Update status based on payments and date
  def update_status!
    new_status = if paid?
      "paid"
    elsif amount_paid > 0
      "partial"
    elsif overdue?
      "overdue"
    else
      "pending"
    end

    update(status: new_status)
  end

  # Days until/past due (negative = overdue)
  def days_until_due
    (due_date - Date.today).to_i
  end
end
