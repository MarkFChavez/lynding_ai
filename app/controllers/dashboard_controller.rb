class DashboardController < ApplicationController
  def index
    @total_borrowed = Loan.sum(:amount)
    @total_profit = Loan.all.sum(&:profit)
    @total_collected = Payment.sum(:amount)
    @active_loans_count = Loan.where(status: 'active').count
    @total_loans = Loan.count
    @total_borrowers = Borrower.count

    # Recent loans
    @recent_loans = Loan.includes(:borrower, :referral_agent).order(start_date: :desc).limit(5)

    # Outstanding balance
    @outstanding_balance = Loan.where(status: 'active').sum { |loan| loan.balance_remaining }

    # Overdue loans - loans with overdue installments
    @overdue_loans = Loan.includes(:borrower, :installments)
                         .where(status: 'active')
                         .select { |loan| loan.overdue_installments.any? }
  end
end
