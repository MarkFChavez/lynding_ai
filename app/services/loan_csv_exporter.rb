require 'csv'

class LoanCsvExporter
  def initialize(loan)
    @loan = loan
  end

  def generate
    CSV.generate do |csv|
      # Loan Details Section
      csv << ["LOAN DETAILS"]
      csv << ["Loan ID", @loan.id]
      csv << ["Borrower Name", @loan.borrower.name]
      csv << ["Borrower Email", @loan.borrower.email.to_s]
      csv << ["Borrower Phone", @loan.borrower.phone.to_s]
      csv << ["Borrower Address", @loan.borrower.address.to_s]
      csv << ["Referral Agent", @loan.referral_agent&.name || "N/A"]
      csv << []

      # Loan Terms Section
      csv << ["LOAN TERMS"]
      csv << ["Principal Amount (PHP)", format_currency(@loan.amount)]
      csv << ["Interest Rate (%)", @loan.interest_rate]
      csv << ["Term (Months)", @loan.term_months]
      csv << ["Start Date", @loan.start_date.strftime("%Y-%m-%d")]
      csv << ["Status", @loan.status.capitalize]
      csv << ["Monthly Payment (PHP)", format_currency(@loan.calculate_monthly_installment_amount)]
      csv << []

      # Summary Statistics Section
      csv << ["SUMMARY STATISTICS"]
      csv << ["Total Interest (PHP)", format_currency(@loan.total_interest)]
      csv << ["Total Amount Due (PHP)", format_currency(@loan.total_amount)]
      csv << ["Total Paid (PHP)", format_currency(@loan.total_paid)]
      csv << ["Balance Remaining (PHP)", format_currency(@loan.balance_remaining)]
      csv << ["Payment Progress (%)", payment_percentage]
      csv << []

      # Payment History Section
      csv << ["PAYMENT HISTORY"]
      csv << ["Payment Date", "Amount (PHP)", "Running Balance (PHP)", "Notes", "Recorded By", "Recorded At"]

      running_balance = @loan.total_amount
      @loan.payments.order(:payment_date).each do |payment|
        running_balance -= payment.amount
        csv << [
          payment.payment_date.strftime("%Y-%m-%d"),
          format_currency(payment.amount),
          format_currency(running_balance),
          payment.notes.to_s,
          payment.created_by&.email || "N/A",
          payment.created_at.strftime("%Y-%m-%d %H:%M:%S")
        ]
      end
      csv << []

      # Amortization Schedule Section
      csv << ["AMORTIZATION SCHEDULE"]
      csv << ["Installment #", "Due Date", "Principal (PHP)", "Interest (PHP)", "Total (PHP)", "Amount Paid (PHP)", "Status"]

      @loan.installments.order(:installment_number).each do |installment|
        csv << [
          installment.installment_number,
          installment.due_date.strftime("%Y-%m-%d"),
          format_currency(installment.principal_amount),
          format_currency(installment.interest_amount),
          format_currency(installment.total_amount),
          format_currency(installment.amount_paid),
          installment.status.capitalize
        ]
      end
      csv << []

      # Export Metadata
      csv << ["EXPORT INFORMATION"]
      csv << ["Generated At", Time.current.strftime("%Y-%m-%d %H:%M:%S")]
    end
  end

  private

  def format_currency(amount)
    sprintf("%.2f", amount)
  end

  def payment_percentage
    return "0.00" if @loan.total_amount.zero?
    percentage = (@loan.total_paid / @loan.total_amount * 100).round(2)
    sprintf("%.2f", percentage)
  end
end
