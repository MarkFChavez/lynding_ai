require 'prawn'
require 'prawn/table'

class LoanPdfExporter
  def initialize(loan)
    @loan = loan
  end

  def generate
    Prawn::Document.new(page_size: 'A4', margin: 40) do |pdf|
      # Header
      pdf.text "Loan Details", size: 24, style: :bold, align: :center
      pdf.move_down 20

      # Borrower Information
      pdf.text "Borrower Information", size: 16, style: :bold
      pdf.move_down 10
      borrower_data = [
        ["Name:", @loan.borrower.name],
        ["Email:", @loan.borrower.email || "N/A"],
        ["Phone:", @loan.borrower.phone || "N/A"],
        ["Address:", @loan.borrower.address || "N/A"]
      ]
      pdf.table(borrower_data, cell_style: { borders: [], padding: [2, 5] }, column_widths: [100, 400])
      pdf.move_down 15

      # Loan Terms
      pdf.text "Loan Terms", size: 16, style: :bold
      pdf.move_down 10
      loan_data = [
        ["Principal Amount:", "PHP #{format_currency(@loan.amount)}"],
        ["Interest Rate:", "#{@loan.interest_rate}%"],
        ["Term:", "#{@loan.term_months} months"],
        ["Start Date:", @loan.start_date.strftime("%B %d, %Y")],
        ["Status:", @loan.status.capitalize],
        ["Monthly Payment:", "PHP #{format_currency(@loan.calculate_monthly_installment_amount)}"]
      ]
      if @loan.referral_agent
        loan_data << ["Referral Agent:", @loan.referral_agent.name]
      end
      pdf.table(loan_data, cell_style: { borders: [], padding: [2, 5] }, column_widths: [150, 350])
      pdf.move_down 20

      # Summary Statistics
      pdf.text "Summary", size: 16, style: :bold
      pdf.move_down 10
      summary_data = [
        ["Total Interest:", "PHP #{format_currency(@loan.total_interest)}"],
        ["Total Amount Due:", "PHP #{format_currency(@loan.total_amount)}"],
        ["Total Paid:", "PHP #{format_currency(@loan.total_paid)}"],
        ["Balance Remaining:", "PHP #{format_currency(@loan.balance_remaining)}"],
        ["Payment Progress:", "#{payment_percentage}%"]
      ]
      pdf.table(summary_data, cell_style: { borders: [], padding: [2, 5] }, column_widths: [150, 350])
      pdf.move_down 20

      # Payment History
      if @loan.payments.any?
        pdf.text "Payment History", size: 16, style: :bold
        pdf.move_down 10

        payment_table_data = [["Date", "Amount", "Running Balance", "Notes"]]
        running_balance = @loan.total_amount

        @loan.payments.order(:payment_date).each do |payment|
          running_balance -= payment.amount
          payment_table_data << [
            payment.payment_date.strftime("%m/%d/%Y"),
            "PHP #{format_currency(payment.amount)}",
            "PHP #{format_currency(running_balance)}",
            payment.notes.to_s.truncate(30)
          ]
        end

        pdf.table(payment_table_data,
          header: true,
          row_colors: ["F0F0F0", "FFFFFF"],
          cell_style: { size: 9, padding: [4, 5] },
          column_widths: [80, 100, 120, 200]
        )
        pdf.move_down 20
      end

      # Amortization Schedule
      pdf.start_new_page
      pdf.text "Amortization Schedule", size: 16, style: :bold
      pdf.move_down 10

      amortization_data = [["#", "Due Date", "Principal", "Interest", "Total", "Status"]]

      @loan.installments.order(:installment_number).each do |installment|
        amortization_data << [
          installment.installment_number.to_s,
          installment.due_date.strftime("%m/%d/%Y"),
          "PHP #{format_currency(installment.principal_amount)}",
          "PHP #{format_currency(installment.interest_amount)}",
          "PHP #{format_currency(installment.total_amount)}",
          installment.status.capitalize
        ]
      end

      pdf.table(amortization_data,
        header: true,
        row_colors: ["F0F0F0", "FFFFFF"],
        cell_style: { size: 8, padding: [4, 5] },
        column_widths: [30, 80, 95, 95, 95, 80]
      )

      # Footer
      pdf.move_down 30
      pdf.text "Generated on #{Time.current.strftime("%B %d, %Y at %I:%M %p")}",
        size: 8,
        style: :italic,
        align: :center,
        color: "666666"
    end
  end

  private

  def format_currency(amount)
    sprintf("%.2f", amount).reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
  end

  def payment_percentage
    return "0.00" if @loan.total_amount.zero?
    percentage = (@loan.total_paid / @loan.total_amount * 100).round(2)
    sprintf("%.2f", percentage)
  end
end
