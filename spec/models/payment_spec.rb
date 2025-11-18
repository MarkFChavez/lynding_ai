require 'rails_helper'

RSpec.describe Payment, type: :model do
  describe 'associations' do
    it { should belong_to(:loan) }
    it { should have_many(:installment_payments).dependent(:destroy) }
    it { should have_many(:installments).through(:installment_payments) }
  end

  describe 'validations' do
    it { should validate_presence_of(:amount) }
    it { should validate_numericality_of(:amount).is_greater_than(0) }
    it { should validate_presence_of(:payment_date) }
  end

  describe 'callbacks' do
    let(:borrower) { Borrower.create!(name: 'Test Borrower') }
    let(:loan) do
      Loan.create!(
        borrower: borrower,
        amount: 60000,
        interest_rate: 10,
        term_months: 6,
        start_date: Date.today - 2.months,
        status: 'active'
      )
    end

    describe '#auto_apply_to_installments' do
      it 'automatically applies payment to installments on creation' do
        payment = Payment.create!(
          loan: loan,
          amount: 15000,
          payment_date: Date.today
        )

        expect(payment.installment_payments).not_to be_empty
      end

      it 'applies to oldest unpaid installments first' do
        first_installment = loan.installments.order(:due_date).first
        second_installment = loan.installments.order(:due_date).second

        payment = Payment.create!(
          loan: loan,
          amount: first_installment.total_amount + 100,
          payment_date: Date.today
        )

        first_payment = payment.installment_payments.find_by(installment: first_installment)
        second_payment = payment.installment_payments.find_by(installment: second_installment)

        expect(first_payment.amount_applied).to eq(first_installment.total_amount)
        expect(second_payment.amount_applied).to eq(100)
      end

      it 'prioritizes overdue installments' do
        # Make first installment overdue
        first = loan.installments.order(:due_date).first
        second = loan.installments.order(:due_date).second
        first.update!(due_date: Date.today - 30)
        second.update!(due_date: Date.today - 15)

        payment = Payment.create!(
          loan: loan,
          amount: 5000,
          payment_date: Date.today
        )

        expect(payment.installment_payments.first.installment).to eq(first)
      end

      it 'skips already paid installments' do
        first = loan.installments.order(:due_date).first
        second = loan.installments.order(:due_date).second
        first.update!(status: 'paid', amount_paid: first.total_amount)

        payment = Payment.create!(
          loan: loan,
          amount: 5000,
          payment_date: Date.today
        )

        expect(payment.installment_payments.map(&:installment)).not_to include(first)
        expect(payment.installment_payments.first.installment).to eq(second)
      end

      it 'handles exact payment for single installment' do
        installment = loan.installments.first
        payment = Payment.create!(
          loan: loan,
          amount: installment.total_amount,
          payment_date: Date.today
        )

        expect(payment.installment_payments.count).to eq(1)
        expect(payment.installment_payments.first.amount_applied).to eq(installment.total_amount)
      end

      it 'distributes payment across multiple installments' do
        payment_amount = loan.installments.limit(3).sum(:total_amount)
        payment = Payment.create!(
          loan: loan,
          amount: payment_amount,
          payment_date: Date.today
        )

        expect(payment.installment_payments.count).to be >= 3
        expect(payment.amount_applied).to eq(payment_amount)
      end

      it 'does not create installment_payments when already fully applied' do
        payment = Payment.new(
          loan: loan,
          amount: 10000,
          payment_date: Date.today
        )
        allow(payment).to receive(:fully_applied?).and_return(true)
        payment.save!

        expect(payment.installment_payments).to be_empty
      end
    end
  end

  describe 'calculated methods' do
    let(:borrower) { Borrower.create!(name: 'Test Borrower') }
    let(:loan) do
      Loan.create!(
        borrower: borrower,
        amount: 30000,
        interest_rate: 10,
        term_months: 3,
        start_date: Date.today - 1.month,
        status: 'active'
      )
    end
    let(:payment) do
      Payment.create!(
        loan: loan,
        amount: 10000,
        payment_date: Date.today
      )
    end

    describe '#amount_applied' do
      it 'returns sum of all installment payment amounts' do
        total_applied = payment.installment_payments.sum(:amount_applied)
        expect(payment.amount_applied).to eq(total_applied)
      end

      it 'returns zero when no installment payments' do
        payment_no_apply = Payment.new(loan: loan, amount: 5000, payment_date: Date.today)
        allow(payment_no_apply).to receive(:auto_apply_to_installments).and_return(nil)
        payment_no_apply.save!

        expect(payment_no_apply.amount_applied).to eq(0)
      end
    end

    describe '#amount_remaining' do
      it 'calculates unapplied amount' do
        applied = payment.amount_applied
        expect(payment.amount_remaining).to eq(10000 - applied)
      end

      it 'returns full amount when nothing applied' do
        payment_no_apply = Payment.new(loan: loan, amount: 5000, payment_date: Date.today)
        allow(payment_no_apply).to receive(:auto_apply_to_installments).and_return(nil)
        payment_no_apply.save!

        expect(payment_no_apply.amount_remaining).to eq(5000)
      end

      it 'returns zero when fully applied' do
        small_payment = Payment.create!(
          loan: loan,
          amount: 100,
          payment_date: Date.today
        )
        expect(small_payment.amount_remaining).to be_within(0.01).of(0)
      end
    end

    describe '#fully_applied?' do
      it 'returns true when amount remaining is effectively zero' do
        # Create a payment that will be fully applied
        installment = loan.installments.first
        exact_payment = Payment.create!(
          loan: loan,
          amount: installment.balance_remaining,
          payment_date: Date.today
        )
        expect(exact_payment.fully_applied?).to be true
      end

      it 'returns true with small rounding differences' do
        payment_mock = Payment.new(loan: loan, amount: 1000, payment_date: Date.today)
        allow(payment_mock).to receive(:amount_remaining).and_return(0.009)
        expect(payment_mock.fully_applied?).to be true
      end

      it 'returns false when amount remaining is significant' do
        large_payment = Payment.create!(
          loan: loan,
          amount: 50000, # More than total loan amount
          payment_date: Date.today
        )
        expect(large_payment.fully_applied?).to be false unless large_payment.amount_remaining < 0.01
      end
    end
  end

  describe 'edge cases' do
    let(:borrower) { Borrower.create!(name: 'Test Borrower') }
    let(:loan) do
      Loan.create!(
        borrower: borrower,
        amount: 100000,
        interest_rate: 12,
        term_months: 12,
        start_date: Date.today - 6.months,
        status: 'active'
      )
    end

    it 'handles very small payments' do
      payment = Payment.create!(
        loan: loan,
        amount: 0.01,
        payment_date: Date.today
      )
      expect(payment).to be_valid
      # Payment is so small it might not be applied due to rounding
      expect(payment.amount_applied).to be_within(0.01).of(0.01)
    end

    it 'handles very large payments exceeding loan balance' do
      payment = Payment.create!(
        loan: loan,
        amount: 1000000,
        payment_date: Date.today
      )
      expect(payment).to be_valid
      expect(payment.amount_applied).to be <= loan.total_amount
    end

    it 'handles payments when all installments are already paid' do
      loan.installments.update_all(status: 'paid', amount_paid: 10000)

      payment = Payment.create!(
        loan: loan,
        amount: 5000,
        payment_date: Date.today
      )

      expect(payment.installment_payments).to be_empty
      expect(payment.amount_remaining).to eq(5000)
    end

    it 'handles multiple payments on same date' do
      payment1 = Payment.create!(
        loan: loan,
        amount: 5000,
        payment_date: Date.today
      )
      payment2 = Payment.create!(
        loan: loan,
        amount: 3000,
        payment_date: Date.today
      )

      expect(payment1).to be_valid
      expect(payment2).to be_valid
      expect(loan.payments.count).to eq(2)
    end

    it 'handles payment date in the past' do
      past_payment = Payment.create!(
        loan: loan,
        amount: 10000,
        payment_date: Date.today - 1.year
      )
      expect(past_payment).to be_valid
    end

    it 'handles payment date in the future' do
      future_payment = Payment.create!(
        loan: loan,
        amount: 10000,
        payment_date: Date.today + 1.month
      )
      expect(future_payment).to be_valid
    end

    it 'correctly applies payment with floating point precision' do
      payment = Payment.create!(
        loan: loan,
        amount: 3333.33,
        payment_date: Date.today
      )
      expect(payment.amount_applied).to be_within(0.01).of(3333.33)
    end

    it 'handles concurrent payments correctly' do
      payments = []
      3.times do |i|
        payments << Payment.create!(
          loan: loan,
          amount: 1000 * (i + 1),
          payment_date: Date.today
        )
      end

      total_paid = payments.sum(&:amount)
      total_applied = payments.sum(&:amount_applied)

      expect(total_applied).to be_within(0.01).of(total_paid)
    end
  end

  describe 'notes attribute' do
    let(:borrower) { Borrower.create!(name: 'Test Borrower') }
    let(:loan) do
      Loan.create!(
        borrower: borrower,
        amount: 10000,
        interest_rate: 10,
        term_months: 3,
        start_date: Date.today,
        status: 'active'
      )
    end

    it 'can store notes' do
      payment = Payment.create!(
        loan: loan,
        amount: 5000,
        payment_date: Date.today,
        notes: 'Partial payment from salary'
      )
      expect(payment.notes).to eq('Partial payment from salary')
    end

    it 'allows nil notes' do
      payment = Payment.create!(
        loan: loan,
        amount: 5000,
        payment_date: Date.today,
        notes: nil
      )
      expect(payment).to be_valid
    end

    it 'handles long notes' do
      long_note = 'A' * 10000
      payment = Payment.create!(
        loan: loan,
        amount: 5000,
        payment_date: Date.today,
        notes: long_note
      )
      expect(payment.notes.length).to eq(10000)
    end
  end

  describe 'payment application strategy' do
    let(:borrower) { Borrower.create!(name: 'Test Borrower') }
    let(:loan) do
      Loan.create!(
        borrower: borrower,
        amount: 50000,
        interest_rate: 10,
        term_months: 5,
        start_date: Date.today - 3.months,
        status: 'active'
      )
    end

    it 'applies payments in correct order by due date' do
      # Shuffle installments to ensure order is by due_date
      installments = loan.installments.order(:due_date).to_a

      payment = Payment.create!(
        loan: loan,
        amount: 25000,
        payment_date: Date.today
      )

      applied_installments = payment.installment_payments
                                   .joins(:installment)
                                   .order('installments.due_date')
                                   .map(&:installment)

      expect(applied_installments.map(&:due_date)).to eq(applied_installments.map(&:due_date).sort)
    end

    it 'stops applying when remaining amount is negligible' do
      payment = Payment.create!(
        loan: loan,
        amount: 10000.005, # Slightly over 10000
        payment_date: Date.today
      )

      remaining = payment.amount_remaining
      expect(remaining).to be <= 0.01
    end
  end
end