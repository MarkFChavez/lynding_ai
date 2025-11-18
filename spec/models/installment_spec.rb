require 'rails_helper'

RSpec.describe Installment, type: :model do
  describe 'associations' do
    it { should belong_to(:loan) }
    it { should have_many(:installment_payments).dependent(:destroy) }
    it { should have_many(:payments).through(:installment_payments) }
  end

  describe 'validations' do
    it { should validate_presence_of(:installment_number) }
    it { should validate_numericality_of(:installment_number).only_integer.is_greater_than(0) }

    it { should validate_presence_of(:principal_amount) }
    it { should validate_numericality_of(:principal_amount).is_greater_than(0) }

    it { should validate_presence_of(:interest_amount) }
    it { should validate_numericality_of(:interest_amount).is_greater_than_or_equal_to(0) }

    it { should validate_presence_of(:total_amount) }
    it { should validate_numericality_of(:total_amount).is_greater_than(0) }

    it { should validate_presence_of(:due_date) }
    it { should validate_presence_of(:status) }
    it { should validate_inclusion_of(:status).in_array(%w[pending partial paid overdue]) }

    it { should validate_numericality_of(:amount_paid).is_greater_than_or_equal_to(0) }
  end

  describe 'calculations' do
    let(:borrower) { Borrower.create!(name: 'Test Borrower') }
    let(:loan) do
      Loan.create!(
        borrower: borrower,
        amount: 120000,
        interest_rate: 10,
        term_months: 12,
        start_date: Date.today - 2.months,
        status: 'active'
      )
    end
    let(:installment) { loan.installments.first }

    describe '#balance_remaining' do
      it 'returns full amount when no payment made' do
        expect(installment.balance_remaining).to eq(installment.total_amount)
      end

      it 'calculates remaining balance after partial payment' do
        installment.update!(amount_paid: 5000)
        expected = installment.total_amount - 5000
        expect(installment.balance_remaining).to eq(expected)
      end

      it 'returns zero when fully paid' do
        installment.update!(amount_paid: installment.total_amount)
        expect(installment.balance_remaining).to be_within(0.01).of(0)
      end

      it 'handles overpayment gracefully' do
        installment.update!(amount_paid: installment.total_amount + 100)
        expect(installment.balance_remaining).to be < 0
      end
    end

    describe '#paid?' do
      it 'returns false when status is not paid' do
        installment.update!(status: 'pending')
        expect(installment.paid?).to be false
      end

      it 'returns true when status is paid' do
        installment.update!(status: 'paid')
        expect(installment.paid?).to be true
      end

      it 'returns true when balance is effectively zero' do
        installment.update!(amount_paid: installment.total_amount - 0.005)
        expect(installment.paid?).to be true
      end

      it 'considers small rounding differences as paid' do
        installment.update!(amount_paid: installment.total_amount - 0.009)
        expect(installment.paid?).to be true
      end
    end

    describe '#overdue?' do
      it 'returns false for future due dates' do
        future_installment = loan.installments.where('due_date > ?', Date.today).first
        expect(future_installment.overdue?).to be false if future_installment
      end

      it 'returns true for past due dates when not paid' do
        past_installment = loan.installments.first
        past_installment.update!(due_date: Date.today - 1, status: 'pending')
        expect(past_installment.overdue?).to be true
      end

      it 'returns false for past due dates when paid' do
        past_installment = loan.installments.first
        past_installment.update!(
          due_date: Date.today - 1,
          status: 'paid',
          amount_paid: past_installment.total_amount
        )
        expect(past_installment.overdue?).to be false
      end

      it 'returns false when due today' do
        installment.update!(due_date: Date.today, status: 'pending')
        expect(installment.overdue?).to be false
      end
    end

    describe '#days_until_due' do
      it 'returns positive days for future dates' do
        installment.update!(due_date: Date.today + 10)
        expect(installment.days_until_due).to eq(10)
      end

      it 'returns negative days for past dates' do
        installment.update!(due_date: Date.today - 5)
        expect(installment.days_until_due).to eq(-5)
      end

      it 'returns zero for today' do
        installment.update!(due_date: Date.today)
        expect(installment.days_until_due).to eq(0)
      end
    end
  end

  describe '#update_status!' do
    let(:borrower) { Borrower.create!(name: 'Test Borrower') }
    let(:loan) do
      Loan.create!(
        borrower: borrower,
        amount: 10000,
        interest_rate: 10,
        term_months: 3,
        start_date: Date.today - 2.months,
        status: 'active'
      )
    end
    let(:installment) { loan.installments.first }

    context 'when fully paid' do
      it 'sets status to paid' do
        installment.update!(amount_paid: installment.total_amount)
        installment.update_status!
        expect(installment.status).to eq('paid')
      end

      it 'sets status to paid even with slight underpayment' do
        installment.update!(amount_paid: installment.total_amount - 0.01)
        installment.update_status!
        expect(installment.status).to eq('paid')
      end
    end

    context 'when partially paid' do
      it 'sets status to partial' do
        installment.update!(amount_paid: installment.total_amount / 2, due_date: Date.today + 1)
        installment.update_status!
        expect(installment.status).to eq('partial')
      end
    end

    context 'when overdue and unpaid' do
      it 'sets status to overdue' do
        installment.update!(amount_paid: 0, due_date: Date.today - 1)
        installment.update_status!
        expect(installment.status).to eq('overdue')
      end
    end

    context 'when overdue and partially paid' do
      it 'sets status to partial' do
        installment.update!(amount_paid: 100, due_date: Date.today - 1)
        installment.update_status!
        expect(installment.status).to eq('partial')
      end
    end

    context 'when pending (future date, no payment)' do
      it 'sets status to pending' do
        installment.update!(amount_paid: 0, due_date: Date.today + 30)
        installment.update_status!
        expect(installment.status).to eq('pending')
      end
    end
  end

  describe 'edge cases' do
    let(:borrower) { Borrower.create!(name: 'Test Borrower') }
    let(:loan) do
      Loan.create!(
        borrower: borrower,
        amount: 50000,
        interest_rate: 15,
        term_months: 6,
        start_date: Date.today,
        status: 'active'
      )
    end

    it 'handles very small payment amounts' do
      installment = loan.installments.first
      installment.update!(amount_paid: 0.01)
      expect(installment.amount_paid).to eq(0.01)
      expect(installment.balance_remaining).to eq(installment.total_amount - 0.01)
    end

    it 'handles maximum installment number' do
      long_term_loan = Loan.create!(
        borrower: borrower,
        amount: 1000000,
        interest_rate: 5,
        term_months: 360,
        start_date: Date.today,
        status: 'active'
      )
      last_installment = long_term_loan.installments.last
      expect(last_installment.installment_number).to eq(360)
    end

    it 'handles zero interest amount' do
      # Create installment directly with zero interest
      installment = Installment.new(
        loan: loan,
        installment_number: 99,
        principal_amount: 1000,
        interest_amount: 0, # Now can be zero
        total_amount: 1000,
        due_date: Date.today + 1,
        status: 'pending',
        amount_paid: 0
      )
      expect(installment).to be_valid
    end

    it 'handles due date on weekend' do
      weekend_date = Date.today.next_occurring(:saturday)
      installment = loan.installments.first
      installment.update!(due_date: weekend_date)
      expect(installment.due_date.saturday?).to be true
    end

    it 'handles due date on holidays' do
      holiday = Date.parse('2025-12-25') # Christmas
      installment = loan.installments.first
      installment.update!(due_date: holiday)
      expect(installment.due_date).to eq(holiday)
    end

    it 'correctly identifies payment status with floating point precision issues' do
      installment = loan.installments.first
      # Simulate floating point precision issue
      installment.update!(amount_paid: installment.total_amount - 0.001)
      expect(installment.paid?).to be true
    end

    it 'handles negative amount paid gracefully' do
      installment = loan.installments.first
      installment.amount_paid = -100
      expect(installment).not_to be_valid
    end
  end

  describe 'payment association' do
    let(:borrower) { Borrower.create!(name: 'Test Borrower') }
    let(:loan) do
      Loan.create!(
        borrower: borrower,
        amount: 30000,
        interest_rate: 10,
        term_months: 3,
        start_date: Date.today,
        status: 'active'
      )
    end
    let(:installment) { loan.installments.first }

    it 'can have multiple payments through installment_payments' do
      # Clear any auto-created installment payments
      InstallmentPayment.destroy_all

      payment1 = Payment.new(loan: loan, amount: 5000, payment_date: Date.today)
      allow(payment1).to receive(:auto_apply_to_installments).and_return(nil)
      payment1.save!

      payment2 = Payment.new(loan: loan, amount: 3000, payment_date: Date.today)
      allow(payment2).to receive(:auto_apply_to_installments).and_return(nil)
      payment2.save!

      InstallmentPayment.create!(
        installment: installment,
        payment: payment1,
        amount_applied: 5000
      )
      InstallmentPayment.create!(
        installment: installment,
        payment: payment2,
        amount_applied: 3000
      )

      expect(installment.payments.count).to eq(2)
      expect(installment.payments).to include(payment1, payment2)
    end

    it 'destroys installment_payments when deleted' do
      # Clear any auto-created installment payments
      InstallmentPayment.destroy_all

      payment = Payment.new(loan: loan, amount: 5000, payment_date: Date.today)
      allow(payment).to receive(:auto_apply_to_installments).and_return(nil)
      payment.save!

      InstallmentPayment.create!(
        installment: installment,
        payment: payment,
        amount_applied: 5000
      )

      expect { installment.destroy }.to change { InstallmentPayment.count }.by(-1)
    end
  end
end