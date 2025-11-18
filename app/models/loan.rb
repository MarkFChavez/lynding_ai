class Loan < ApplicationRecord
  belongs_to :borrower
  belongs_to :referral_agent, optional: true
  belongs_to :created_by, class_name: "User", optional: true
  belongs_to :updated_by, class_name: "User", optional: true
  has_many :payments, dependent: :restrict_with_error
  has_many :installments, dependent: :destroy

  validates :amount, presence: true, numericality: { greater_than: 0 } # Amount in Philippine Peso (PHP)
  validates :interest_rate, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :term_months, presence: true, numericality: { greater_than: 0, only_integer: true }
  validates :start_date, presence: true
  validates :status, presence: true, inclusion: { in: %w[active paid defaulted] }

  validate :critical_fields_unchangeable_after_installments, on: :update

  after_create :generate_installments

  # Calculate total amount to be paid (principal + interest)
  def total_amount
    amount + total_interest
  end

  # Calculate total interest
  def total_interest
    (amount * interest_rate / 100 * term_months / 12).round(2)
  end

  # Calculate total payments made
  def total_paid
    payments.sum(:amount)
  end

  # Calculate remaining balance
  def balance_remaining
    total_amount - total_paid
  end

  # Calculate profit (interest earned)
  def profit
    [total_paid - amount, 0].max
  end

  # Generate installment schedule
  def generate_installments
    return if installments.any? # Don't regenerate if already exist

    monthly_amount = calculate_monthly_installment_amount
    monthly_principal = amount / term_months.to_f
    monthly_interest = total_interest / term_months.to_f

    term_months.times do |i|
      installments.create!(
        installment_number: i + 1,
        principal_amount: monthly_principal.round(2),
        interest_amount: monthly_interest.round(2),
        total_amount: monthly_amount.round(2),
        due_date: start_date + (i + 1).months,
        status: "pending",
        amount_paid: 0
      )
    end

    # Adjust last installment for any rounding differences
    adjust_final_installment
  end

  # Calculate equal monthly payment
  def calculate_monthly_installment_amount
    total_amount / term_months.to_f
  end

  # Adjust final installment to account for rounding
  def adjust_final_installment
    last = installments.order(:installment_number).last
    return unless last

    expected_total = total_amount
    actual_total = installments.sum(:total_amount)
    difference = expected_total - actual_total

    if difference.abs > 0.01
      last.update(
        total_amount: last.total_amount + difference,
        principal_amount: last.principal_amount + difference
      )
    end
  end

  # Next unpaid installment
  def next_installment
    installments.where.not(status: "paid")
                .order(:due_date)
                .first
  end

  # Overdue installments
  def overdue_installments
    installments.where("due_date < ? AND status != ?", Date.today, "paid")
  end

  # Check if loan payment schedule is current
  def current?
    overdue_installments.none?
  end

  private

  # Prevent changes to critical fields after installments are generated
  def critical_fields_unchangeable_after_installments
    return unless installments.any? # Allow all changes if no installments yet

    critical_fields = {
      amount: "loan amount",
      interest_rate: "interest rate",
      term_months: "loan term",
      start_date: "start date"
    }

    critical_fields.each do |field, label|
      if send("#{field}_changed?")
        errors.add(field, "cannot be changed after installments are generated. Delete and recreate the loan if you need to change #{label}.")
      end
    end
  end
end
