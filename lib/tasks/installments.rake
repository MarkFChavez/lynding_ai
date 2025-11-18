namespace :installments do
  desc "Generate installments for existing loans"
  task backfill: :environment do
    puts "Backfilling installments for existing loans..."

    loan_count = 0
    Loan.find_each do |loan|
      next if loan.installments.any?

      puts "  Generating installments for Loan ##{loan.id} (#{loan.borrower.name})"
      loan.generate_installments

      # Apply existing payments to installments
      loan.payments.order(:payment_date).each do |payment|
        payment.send(:auto_apply_to_installments)
      end

      # Update installment statuses
      loan.installments.each(&:update_status!)

      loan_count += 1
    end

    puts "Done! Generated installments for #{loan_count} loans"
  end

  desc "Update overdue installment statuses"
  task update_overdue: :environment do
    puts "Updating overdue installment statuses..."

    updated_count = 0
    Installment.where("due_date < ? AND status IN (?)", Date.today, ["pending", "partial"]).find_each do |installment|
      installment.update_status!
      updated_count += 1 if installment.status == "overdue"
    end

    puts "Done! Updated #{updated_count} installments to overdue status"
  end

  desc "Validate installment data"
  task validate: :environment do
    puts "Validating installment data..."
    errors = []

    Loan.includes(:installments, :payments).find_each do |loan|
      # Check installment count
      if loan.installments.count != loan.term_months
        errors << "Loan ##{loan.id}: Expected #{loan.term_months} installments, found #{loan.installments.count}"
      end

      # Check total amounts match
      installment_total = loan.installments.sum(:total_amount)
      expected_total = loan.total_amount
      if (installment_total - expected_total).abs > 1.0 # Allow $1 rounding difference
        errors << "Loan ##{loan.id}: Installment total (#{installment_total}) doesn't match loan total (#{expected_total})"
      end

      # Check payment allocation
      payment_total = loan.payments.sum(:amount)
      applied_total = InstallmentPayment.joins(:installment).where(installments: { loan_id: loan.id }).sum(:amount_applied)
      if (payment_total - applied_total).abs > 0.01
        errors << "Loan ##{loan.id}: Payment total (#{payment_total}) doesn't match applied total (#{applied_total})"
      end
    end

    if errors.any?
      puts "Found #{errors.count} errors:"
      errors.each { |e| puts "  - #{e}" }
      exit 1
    else
      puts "All validations passed! ✓"
      puts "  Total loans: #{Loan.count}"
      puts "  Loans with installments: #{Loan.joins(:installments).distinct.count}"
      puts "  Total installments: #{Installment.count}"
      puts "  Total installment payments: #{InstallmentPayment.count}"
    end
  end
end
