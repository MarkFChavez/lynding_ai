class InstallmentPayment < ApplicationRecord
  belongs_to :installment
  belongs_to :payment

  validates :amount_applied, presence: true, numericality: { greater_than: 0 }

  validate :amount_within_bounds

  after_save :update_installment_amount_paid
  after_destroy :update_installment_amount_paid

  private

  def amount_within_bounds
    if amount_applied && payment && amount_applied > payment.amount + 0.01
      errors.add(:amount_applied, "cannot exceed payment amount")
    end

    if amount_applied && installment && amount_applied > installment.balance_remaining + 0.01
      errors.add(:amount_applied, "cannot exceed installment balance")
    end
  end

  def update_installment_amount_paid
    installment.update(
      amount_paid: installment.installment_payments.sum(:amount_applied)
    )
    installment.update_status!
  end
end
