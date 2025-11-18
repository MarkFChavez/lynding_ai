require 'rails_helper'

RSpec.describe Loan, type: :model do
  describe 'associations' do
    it { should belong_to(:borrower) }
    it { should belong_to(:referral_agent).optional }
    it { should have_many(:payments).dependent(:restrict_with_error) }
    it { should have_many(:installments).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:amount) }
    it { should validate_numericality_of(:amount).is_greater_than(0) }

    it { should validate_presence_of(:interest_rate) }
    it { should validate_numericality_of(:interest_rate).is_greater_than_or_equal_to(0) }

    it { should validate_presence_of(:term_months) }
    it { should validate_numericality_of(:term_months).only_integer.is_greater_than(0) }

    it { should validate_presence_of(:start_date) }
    it { should validate_presence_of(:status) }
    it { should validate_inclusion_of(:status).in_array(%w[active paid defaulted]) }
  end

  describe 'callbacks' do
    let(:borrower) { Borrower.create!(name: 'Test Borrower') }

    it 'generates installments after creation' do
      loan = Loan.create!(
        borrower: borrower,
        amount: 120000,
        interest_rate: 12,
        term_months: 12,
        start_date: Date.today,
        status: 'active'
      )

      expect(loan.installments.count).to eq(12)
    end

    it 'does not regenerate installments if they already exist' do
      loan = Loan.create!(
        borrower: borrower,
        amount: 120000,
        interest_rate: 12,
        term_months: 12,
        start_date: Date.today,
        status: 'active'
      )

      initial_count = loan.installments.count
      loan.generate_installments
      expect(loan.installments.count).to eq(initial_count)
    end
  end

  describe 'calculations' do
    let(:borrower) { Borrower.create!(name: 'Test Borrower') }
    let(:loan) do
      Loan.create!(
        borrower: borrower,
        amount: 100000,
        interest_rate: 12,
        term_months: 12,
        start_date: Date.today,
        status: 'active'
      )
    end

    describe '#total_interest' do
      it 'calculates correct interest for a year' do
        expect(loan.total_interest).to eq(12000.0)
      end

      it 'calculates correct interest for partial year' do
        loan_6_months = Loan.create!(
          borrower: borrower,
          amount: 100000,
          interest_rate: 12,
          term_months: 6,
          start_date: Date.today,
          status: 'active'
        )
        expect(loan_6_months.total_interest).to eq(6000.0)
      end

      it 'handles zero interest rate' do
        loan_zero_interest = Loan.create!(
          borrower: borrower,
          amount: 100000,
          interest_rate: 0,
          term_months: 12,
          start_date: Date.today,
          status: 'active'
        )
        expect(loan_zero_interest.total_interest).to eq(0)
      end
    end

    describe '#total_amount' do
      it 'calculates principal plus interest' do
        expect(loan.total_amount).to eq(112000.0)
      end
    end

    describe '#calculate_monthly_installment_amount' do
      it 'divides total amount equally across months' do
        expected_monthly = 112000.0 / 12
        expect(loan.calculate_monthly_installment_amount).to be_within(0.01).of(expected_monthly)
      end
    end

    describe '#total_paid' do
      it 'returns zero when no payments made' do
        expect(loan.total_paid).to eq(0)
      end

      it 'sums all payment amounts' do
        Payment.create!(loan: loan, amount: 5000, payment_date: Date.today)
        Payment.create!(loan: loan, amount: 3000, payment_date: Date.today)
        expect(loan.total_paid).to eq(8000)
      end
    end

    describe '#balance_remaining' do
      it 'returns full amount when no payments made' do
        expect(loan.balance_remaining).to eq(112000.0)
      end

      it 'calculates remaining balance after payments' do
        Payment.create!(loan: loan, amount: 50000, payment_date: Date.today)
        expect(loan.balance_remaining).to eq(62000.0)
      end

      it 'returns zero when fully paid' do
        Payment.create!(loan: loan, amount: 112000, payment_date: Date.today)
        expect(loan.balance_remaining).to eq(0)
      end
    end

    describe '#profit' do
      it 'returns zero when no payments made' do
        expect(loan.profit).to eq(0)
      end

      it 'returns zero when payments less than principal' do
        Payment.create!(loan: loan, amount: 50000, payment_date: Date.today)
        expect(loan.profit).to eq(0)
      end

      it 'calculates profit when payments exceed principal' do
        Payment.create!(loan: loan, amount: 105000, payment_date: Date.today)
        expect(loan.profit).to eq(5000)
      end
    end
  end

  describe 'installment generation' do
    let(:borrower) { Borrower.create!(name: 'Test Borrower') }
    let(:loan) do
      Loan.create!(
        borrower: borrower,
        amount: 120000,
        interest_rate: 10,
        term_months: 12,
        start_date: Date.parse('2025-01-01'),
        status: 'active'
      )
    end

    it 'creates correct number of installments' do
      expect(loan.installments.count).to eq(12)
    end

    it 'numbers installments sequentially' do
      numbers = loan.installments.order(:installment_number).pluck(:installment_number)
      expect(numbers).to eq((1..12).to_a)
    end

    it 'sets correct due dates' do
      first_installment = loan.installments.find_by(installment_number: 1)
      last_installment = loan.installments.find_by(installment_number: 12)

      expect(first_installment.due_date).to eq(Date.parse('2025-02-01'))
      expect(last_installment.due_date).to eq(Date.parse('2026-01-01'))
    end

    it 'distributes principal and interest correctly' do
      total_principal = loan.installments.sum(:principal_amount)
      total_interest = loan.installments.sum(:interest_amount)

      expect(total_principal).to be_within(0.1).of(120000)
      expect(total_interest).to be_within(0.1).of(12000)
    end

    it 'adjusts final installment for rounding differences' do
      total_installments = loan.installments.sum(:total_amount)
      expect(total_installments).to be_within(0.01).of(loan.total_amount)
    end

    it 'sets all installments to pending status initially' do
      statuses = loan.installments.pluck(:status).uniq
      expect(statuses).to eq(['pending'])
    end

    it 'sets amount_paid to zero initially' do
      amounts_paid = loan.installments.pluck(:amount_paid).uniq
      expect(amounts_paid).to eq([0.0])
    end
  end

  describe '#next_installment' do
    let(:borrower) { Borrower.create!(name: 'Test Borrower') }
    let(:loan) do
      Loan.create!(
        borrower: borrower,
        amount: 60000,
        interest_rate: 10,
        term_months: 6,
        start_date: Date.today - 3.months,
        status: 'active'
      )
    end

    it 'returns first unpaid installment' do
      first_installment = loan.installments.order(:due_date).first
      expect(loan.next_installment).to eq(first_installment)
    end

    it 'skips paid installments' do
      first = loan.installments.order(:due_date).first
      second = loan.installments.order(:due_date).second

      first.update!(status: 'paid')
      expect(loan.next_installment).to eq(second)
    end

    it 'returns nil when all installments are paid' do
      loan.installments.update_all(status: 'paid')
      expect(loan.next_installment).to be_nil
    end
  end

  describe '#overdue_installments' do
    let(:borrower) { Borrower.create!(name: 'Test Borrower') }
    let(:loan) do
      Loan.create!(
        borrower: borrower,
        amount: 36000,
        interest_rate: 10,
        term_months: 3,
        start_date: Date.today - 4.months,
        status: 'active'
      )
    end

    it 'returns installments past due date' do
      overdue = loan.overdue_installments
      expect(overdue.count).to be > 0
      overdue.each do |installment|
        expect(installment.due_date).to be < Date.today
        expect(installment.status).not_to eq('paid')
      end
    end

    it 'excludes paid installments even if past due date' do
      old_installment = loan.installments.where('due_date < ?', Date.today).first
      old_installment.update!(status: 'paid')

      overdue = loan.overdue_installments
      expect(overdue).not_to include(old_installment)
    end

    it 'excludes future installments' do
      future_loan = Loan.create!(
        borrower: borrower,
        amount: 10000,
        interest_rate: 10,
        term_months: 6,
        start_date: Date.today,
        status: 'active'
      )

      expect(future_loan.overdue_installments).to be_empty
    end
  end

  describe '#current?' do
    let(:borrower) { Borrower.create!(name: 'Test Borrower') }

    it 'returns true when no overdue installments' do
      loan = Loan.create!(
        borrower: borrower,
        amount: 10000,
        interest_rate: 10,
        term_months: 6,
        start_date: Date.today,
        status: 'active'
      )
      expect(loan.current?).to be true
    end

    it 'returns false when has overdue installments' do
      loan = Loan.create!(
        borrower: borrower,
        amount: 10000,
        interest_rate: 10,
        term_months: 2,
        start_date: Date.today - 3.months,
        status: 'active'
      )
      expect(loan.current?).to be false
    end
  end

  describe 'edge cases' do
    let(:borrower) { Borrower.create!(name: 'Test Borrower') }

    it 'handles very small loan amounts' do
      loan = Loan.create!(
        borrower: borrower,
        amount: 0.01,
        interest_rate: 10,
        term_months: 1,
        start_date: Date.today,
        status: 'active'
      )
      expect(loan).to be_valid
      expect(loan.installments.count).to eq(1)
    end

    it 'handles very large loan amounts' do
      loan = Loan.create!(
        borrower: borrower,
        amount: 999999999,
        interest_rate: 10,
        term_months: 360,
        start_date: Date.today,
        status: 'active'
      )
      expect(loan).to be_valid
      expect(loan.installments.count).to eq(360)
    end

    it 'handles single month term' do
      loan = Loan.create!(
        borrower: borrower,
        amount: 10000,
        interest_rate: 12,
        term_months: 1,
        start_date: Date.today,
        status: 'active'
      )
      expect(loan.installments.count).to eq(1)
      expect(loan.installments.first.total_amount).to be_within(0.01).of(loan.total_amount)
    end

    it 'handles decimal interest rates' do
      loan = Loan.create!(
        borrower: borrower,
        amount: 100000,
        interest_rate: 7.5,
        term_months: 12,
        start_date: Date.today,
        status: 'active'
      )
      expect(loan.total_interest).to eq(7500.0)
    end

    it 'handles leap year dates correctly' do
      loan = Loan.create!(
        borrower: borrower,
        amount: 10000,
        interest_rate: 10,
        term_months: 12,
        start_date: Date.parse('2024-02-29'),
        status: 'active'
      )

      march_installment = loan.installments.find_by(installment_number: 1)
      expect(march_installment.due_date).to eq(Date.parse('2024-03-29'))
    end
  end
end