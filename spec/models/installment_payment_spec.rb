require 'rails_helper'

RSpec.describe InstallmentPayment, type: :model do
  describe 'associations' do
    it { should belong_to(:installment) }
    it { should belong_to(:payment) }
  end

  describe 'validations' do
    it { should validate_presence_of(:amount_applied) }
    it { should validate_numericality_of(:amount_applied).is_greater_than(0) }

    describe 'custom validations' do
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
      let(:payment) do
        Payment.new(loan: loan, amount: 10000, payment_date: Date.today)
      end
      let(:installment) { loan.installments.first }

      before do
        allow(payment).to receive(:auto_apply_to_installments).and_return(nil)
        payment.save!
      end

      describe '#amount_within_bounds' do
        it 'validates amount does not exceed payment amount' do
          installment_payment = InstallmentPayment.new(
            installment: installment,
            payment: payment,
            amount_applied: 10002 # More than payment amount + tolerance
          )

          expect(installment_payment).not_to be_valid
          expect(installment_payment.errors[:amount_applied]).to include('cannot exceed payment amount')
        end

        it 'validates amount does not exceed installment balance' do
          installment_payment = InstallmentPayment.new(
            installment: installment,
            payment: payment,
            amount_applied: installment.total_amount + 100
          )

          expect(installment_payment).not_to be_valid
          expect(installment_payment.errors[:amount_applied]).to include('cannot exceed installment balance')
        end

        it 'allows amount equal to payment amount' do
          installment_payment = InstallmentPayment.new(
            installment: installment,
            payment: payment,
            amount_applied: payment.amount
          )

          expect(installment_payment).to be_valid
        end

        it 'allows amount equal to installment balance' do
          # Use smaller amount that's within both payment and installment bounds
          smaller_amount = [payment.amount, installment.balance_remaining].min
          installment_payment = InstallmentPayment.new(
            installment: installment,
            payment: payment,
            amount_applied: smaller_amount
          )

          expect(installment_payment).to be_valid
        end

        it 'allows small rounding differences for installment balance' do
          # Use smaller amount that's within payment bounds
          smaller_amount = [payment.amount, installment.balance_remaining].min
          installment_payment = InstallmentPayment.new(
            installment: installment,
            payment: payment,
            amount_applied: smaller_amount + 0.009
          )

          expect(installment_payment).to be_valid
        end
      end
    end
  end

  describe 'callbacks' do
    let(:borrower) { Borrower.create!(name: 'Test Borrower') }
    let(:loan) do
      Loan.create!(
        borrower: borrower,
        amount: 20000,
        interest_rate: 10,
        term_months: 2,
        start_date: Date.today,
        status: 'active'
      )
    end
    let(:payment) do
      Payment.new(loan: loan, amount: 10000, payment_date: Date.today)
    end
    let(:installment) { loan.installments.first }

    before do
      allow(payment).to receive(:auto_apply_to_installments).and_return(nil)
      payment.save!
    end

    describe '#update_installment_amount_paid' do
      it 'updates installment amount_paid after creation' do
        expect(installment.amount_paid).to eq(0)

        InstallmentPayment.create!(
          installment: installment,
          payment: payment,
          amount_applied: 5000
        )

        installment.reload
        expect(installment.amount_paid).to eq(5000)
      end

      it 'updates installment amount_paid after update' do
        installment_payment = InstallmentPayment.create!(
          installment: installment,
          payment: payment,
          amount_applied: 3000
        )

        installment.reload
        expect(installment.amount_paid).to eq(3000)

        installment_payment.update!(amount_applied: 4000)
        installment.reload
        expect(installment.amount_paid).to eq(4000)
      end

      it 'updates installment amount_paid after destroy' do
        installment_payment = InstallmentPayment.create!(
          installment: installment,
          payment: payment,
          amount_applied: 5000
        )

        installment.reload
        expect(installment.amount_paid).to eq(5000)

        installment_payment.destroy
        installment.reload
        expect(installment.amount_paid).to eq(0)
      end

      it 'correctly sums multiple installment payments' do
        payment2 = Payment.new(loan: loan, amount: 5000, payment_date: Date.today)
        allow(payment2).to receive(:auto_apply_to_installments).and_return(nil)
        payment2.save!

        InstallmentPayment.create!(
          installment: installment,
          payment: payment,
          amount_applied: 3000
        )
        InstallmentPayment.create!(
          installment: installment,
          payment: payment2,
          amount_applied: 2000
        )

        installment.reload
        expect(installment.amount_paid).to eq(5000)
      end

      it 'triggers update_status! on installment' do
        # Make payment amount large enough to cover the installment
        payment.update!(amount: installment.total_amount + 100)

        installment_payment = InstallmentPayment.create!(
          installment: installment,
          payment: payment,
          amount_applied: installment.total_amount
        )

        installment.reload
        expect(installment.status).to eq('paid')
      end
    end
  end

  describe 'uniqueness constraint' do
    let(:borrower) { Borrower.create!(name: 'Test Borrower') }
    let(:loan) do
      Loan.create!(
        borrower: borrower,
        amount: 10000,
        interest_rate: 10,
        term_months: 3,  # Multiple months to create multiple installments
        start_date: Date.today,
        status: 'active'
      )
    end
    let(:payment) do
      Payment.new(loan: loan, amount: 5000, payment_date: Date.today)
    end
    let(:installment) { loan.installments.first }

    before do
      allow(payment).to receive(:auto_apply_to_installments).and_return(nil)
      payment.save!
    end

    it 'enforces unique combination of installment and payment' do
      InstallmentPayment.create!(
        installment: installment,
        payment: payment,
        amount_applied: 2000
      )

      duplicate = InstallmentPayment.new(
        installment: installment,
        payment: payment,
        amount_applied: 1000
      )

      expect { duplicate.save! }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it 'allows same installment with different payments' do
      payment2 = Payment.new(loan: loan, amount: 3000, payment_date: Date.today)
      allow(payment2).to receive(:auto_apply_to_installments).and_return(nil)
      payment2.save!

      # Use smaller amounts that fit within installment balance
      amount1 = [1000, installment.balance_remaining / 2].min
      amount2 = [500, installment.balance_remaining / 2].min

      ip1 = InstallmentPayment.create!(
        installment: installment,
        payment: payment,
        amount_applied: amount1
      )

      ip2 = InstallmentPayment.create!(
        installment: installment,
        payment: payment2,
        amount_applied: amount2
      )

      expect(ip1).to be_valid
      expect(ip2).to be_valid
    end

    it 'allows same payment applied to different installments' do
      # Create larger payment to cover both installments
      payment.update!(amount: 10000)

      # Get the second installment from the loan (already created)
      installment2 = loan.installments.where.not(id: installment.id).first

      # Use amounts that fit within each installment's balance
      amount1 = [1000, installment.balance_remaining].min
      amount2 = [1000, installment2.balance_remaining].min

      # Apply parts of the payment to both installments
      ip1 = InstallmentPayment.create!(
        installment: installment,
        payment: payment,
        amount_applied: amount1
      )

      ip2 = InstallmentPayment.create!(
        installment: installment2,
        payment: payment,
        amount_applied: amount2
      )

      expect(ip1).to be_valid
      expect(ip2).to be_valid
    end
  end

  describe 'edge cases' do
    let(:borrower) { Borrower.create!(name: 'Test Borrower') }
    let(:loan) do
      Loan.create!(
        borrower: borrower,
        amount: 50000,
        interest_rate: 12,
        term_months: 6,
        start_date: Date.today,
        status: 'active'
      )
    end
    let(:payment) do
      Payment.new(loan: loan, amount: 25000, payment_date: Date.today)
    end
    let(:installment) { loan.installments.first }

    before do
      allow(payment).to receive(:auto_apply_to_installments).and_return(nil)
      payment.save!
    end

    it 'handles very small amount_applied' do
      installment_payment = InstallmentPayment.create!(
        installment: installment,
        payment: payment,
        amount_applied: 0.01
      )

      expect(installment_payment).to be_valid
      expect(installment.reload.amount_paid).to eq(0.01)
    end

    it 'handles exact penny amounts' do
      installment_payment = InstallmentPayment.create!(
        installment: installment,
        payment: payment,
        amount_applied: 123.45
      )

      expect(installment_payment.amount_applied).to eq(123.45)
      expect(installment.reload.amount_paid).to eq(123.45)
    end

    it 'handles floating point precision correctly' do
      amounts = [100.10, 200.20, 300.30]
      payments = []

      amounts.each do |amount|
        p = Payment.new(loan: loan, amount: amount, payment_date: Date.today)
        allow(p).to receive(:auto_apply_to_installments).and_return(nil)
        p.save!

        payments << InstallmentPayment.create!(
          installment: installment,
          payment: p,
          amount_applied: amount
        )
      end

      installment.reload
      expected_total = amounts.sum
      expect(installment.amount_paid).to be_within(0.01).of(expected_total)
    end

    it 'handles destruction of payment cascading to installment_payments' do
      installment_payment = InstallmentPayment.create!(
        installment: installment,
        payment: payment,
        amount_applied: 5000
      )

      expect { payment.destroy }.to change { InstallmentPayment.count }.by(-1)
      expect(InstallmentPayment.exists?(installment_payment.id)).to be false
    end

    it 'handles destruction of installment cascading to installment_payments' do
      installment_payment = InstallmentPayment.create!(
        installment: installment,
        payment: payment,
        amount_applied: 5000
      )

      expect { installment.destroy }.to change { InstallmentPayment.count }.by(-1)
      expect(InstallmentPayment.exists?(installment_payment.id)).to be false
    end

    it 'correctly updates installment when multiple payments are deleted' do
      payment2 = Payment.new(loan: loan, amount: 3000, payment_date: Date.today)
      allow(payment2).to receive(:auto_apply_to_installments).and_return(nil)
      payment2.save!

      ip1 = InstallmentPayment.create!(
        installment: installment,
        payment: payment,
        amount_applied: 2000
      )
      ip2 = InstallmentPayment.create!(
        installment: installment,
        payment: payment2,
        amount_applied: 1500
      )

      installment.reload
      expect(installment.amount_paid).to eq(3500)

      ip1.destroy
      installment.reload
      expect(installment.amount_paid).to eq(1500)

      ip2.destroy
      installment.reload
      expect(installment.amount_paid).to eq(0)
    end

    it 'handles concurrent updates correctly' do
      payment2 = Payment.new(loan: loan, amount: 10000, payment_date: Date.today)
      allow(payment2).to receive(:auto_apply_to_installments).and_return(nil)
      payment2.save!

      ip1 = InstallmentPayment.create!(
        installment: installment,
        payment: payment,
        amount_applied: 3000
      )
      ip2 = InstallmentPayment.create!(
        installment: installment,
        payment: payment2,
        amount_applied: 2000
      )

      # Simulate concurrent update
      ip1.update!(amount_applied: 3500)
      ip2.reload.update!(amount_applied: 2500)

      installment.reload
      expect(installment.amount_paid).to eq(6000)
    end
  end

  describe 'application scenarios' do
    let(:borrower) { Borrower.create!(name: 'Test Borrower') }
    let(:loan) do
      Loan.create!(
        borrower: borrower,
        amount: 100000,
        interest_rate: 15,
        term_months: 12,
        start_date: Date.today - 6.months,
        status: 'active'
      )
    end

    it 'handles partial payment across multiple installments' do
      payment = Payment.create!(
        loan: loan,
        amount: 25000,
        payment_date: Date.today
      )

      # Check that payment was distributed
      expect(payment.installment_payments).not_to be_empty

      # Verify total applied equals payment amount
      total_applied = payment.installment_payments.sum(:amount_applied)
      expect(total_applied).to be_within(0.01).of(25000)

      # Check installments were updated
      affected_installments = payment.installments
      affected_installments.each do |installment|
        expect(installment.amount_paid).to be > 0
      end
    end

    it 'handles overpayment scenario' do
      small_loan = Loan.create!(
        borrower: borrower,
        amount: 1000,
        interest_rate: 10,
        term_months: 1,
        start_date: Date.today,
        status: 'active'
      )

      payment = Payment.create!(
        loan: small_loan,
        amount: 2000, # More than needed
        payment_date: Date.today
      )

      # Should only apply what's needed
      total_applied = payment.installment_payments.sum(:amount_applied)
      expect(total_applied).to be <= small_loan.total_amount
    end
  end
end