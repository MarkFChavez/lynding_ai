require 'rails_helper'

RSpec.describe Borrower, type: :model do
  describe 'associations' do
    it { should have_many(:loans).dependent(:restrict_with_error) }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }

    describe 'email validation' do
      it 'allows blank email' do
        borrower = Borrower.new(name: 'John Doe', email: '')
        expect(borrower).to be_valid
      end

      it 'allows nil email' do
        borrower = Borrower.new(name: 'John Doe', email: nil)
        expect(borrower).to be_valid
      end

      it 'accepts valid email addresses' do
        valid_emails = [
          'user@example.com',
          'user.name@example.com',
          'user+tag@example.co.uk',
          'user_123@test-domain.org'
        ]

        valid_emails.each do |email|
          borrower = Borrower.new(name: 'John Doe', email: email)
          expect(borrower).to be_valid, "#{email} should be valid"
        end
      end

      it 'rejects invalid email addresses' do
        invalid_emails = [
          'invalid',
          '@example.com',
          'user@',
          'user space@example.com',
          'user@example..com'
        ]

        invalid_emails.each do |email|
          borrower = Borrower.new(name: 'John Doe', email: email)
          expect(borrower).not_to be_valid, "#{email} should be invalid"
          expect(borrower.errors[:email]).to be_present
        end
      end
    end
  end

  describe 'attributes' do
    let(:borrower) { Borrower.new }

    it 'has name attribute' do
      borrower.name = 'Jane Smith'
      expect(borrower.name).to eq('Jane Smith')
    end

    it 'has email attribute' do
      borrower.email = 'jane@example.com'
      expect(borrower.email).to eq('jane@example.com')
    end

    it 'has phone attribute' do
      borrower.phone = '+63 912 345 6789'
      expect(borrower.phone).to eq('+63 912 345 6789')
    end

    it 'has address attribute' do
      borrower.address = '123 Main St, Manila, Philippines'
      expect(borrower.address).to eq('123 Main St, Manila, Philippines')
    end
  end

  describe 'edge cases' do
    it 'handles very long names' do
      long_name = 'A' * 1000
      borrower = Borrower.new(name: long_name)
      expect(borrower).to be_valid
      expect(borrower.name.length).to eq(1000)
    end

    it 'handles special characters in name' do
      special_names = [
        "O'Brien",
        "María García",
        "Jean-Pierre",
        "李明",
        "José Ñúñez"
      ]

      special_names.each do |name|
        borrower = Borrower.new(name: name)
        expect(borrower).to be_valid
      end
    end

    it 'handles empty strings vs nil differently' do
      borrower_empty = Borrower.new(name: '')
      borrower_nil = Borrower.new(name: nil)

      expect(borrower_empty).not_to be_valid
      expect(borrower_nil).not_to be_valid
    end
  end

  describe 'loan association' do
    let(:borrower) { Borrower.create!(name: 'Test Borrower', email: 'test@example.com') }

    it 'can have multiple loans' do
      loan1 = Loan.create!(
        borrower: borrower,
        amount: 10000,
        interest_rate: 10,
        term_months: 12,
        start_date: Date.today,
        status: 'active'
      )
      loan2 = Loan.create!(
        borrower: borrower,
        amount: 20000,
        interest_rate: 8,
        term_months: 6,
        start_date: Date.today,
        status: 'active'
      )

      expect(borrower.loans.count).to eq(2)
      expect(borrower.loans).to include(loan1, loan2)
    end

    it 'prevents deletion when borrower has loans' do
      loan = Loan.create!(
        borrower: borrower,
        amount: 10000,
        interest_rate: 10,
        term_months: 12,
        start_date: Date.today,
        status: 'active'
      )

      expect { borrower.destroy }.not_to change { Loan.count }
      expect(borrower.errors[:base]).to include('Cannot delete record because dependent loans exist')
      expect(Loan.exists?(loan.id)).to be_truthy
    end

    it 'allows deletion when borrower has no loans' do
      borrower_id = borrower.id
      expect(borrower.destroy).to be_truthy
      expect(Borrower.exists?(borrower_id)).to be_falsey
    end
  end
end