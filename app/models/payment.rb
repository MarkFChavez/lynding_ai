class Payment < ApplicationRecord
  belongs_to :loan
  belongs_to :created_by, class_name: "User", optional: true
  belongs_to :updated_by, class_name: "User", optional: true
  has_many :installment_payments, dependent: :destroy
  has_many :installments, through: :installment_payments

  validates :amount, presence: true, numericality: { greater_than: 0 } # Amount in Philippine Peso (PHP)
  validates :payment_date, presence: true

  after_create :auto_apply_to_installments

  # Amount already applied to installments
  def amount_applied
    installment_payments.sum(:amount_applied)
  end

  # Remaining unapplied amount
  def amount_remaining
    amount - amount_applied
  end

  # Is fully applied?
  def fully_applied?
    amount_remaining.abs < 0.01 # Allow small rounding differences
  end

  private

  # Automatically apply payment to oldest unpaid installments
  def auto_apply_to_installments
    return if fully_applied?

    remaining = amount

    # Apply to installments in order: overdue first, then by due date
    loan.installments
        .where.not(status: "paid")
        .order(:due_date)
        .each do |installment|
      break if remaining <= 0.01

      amount_to_apply = [remaining, installment.balance_remaining].min

      # Skip if amount is too small
      next if amount_to_apply <= 0

      InstallmentPayment.create!(
        installment: installment,
        payment: self,
        amount_applied: amount_to_apply
      )

      remaining -= amount_to_apply
    end
  end
end
