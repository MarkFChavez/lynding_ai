require 'rails_helper'

RSpec.describe ReferralAgent, type: :model do
  describe 'associations' do
    it { should have_many(:loans).dependent(:nullify) }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }

    describe 'commission_rate validation' do
      it 'allows nil commission rate' do
        agent = ReferralAgent.new(name: 'Agent Smith')
        expect(agent).to be_valid
      end

      it 'allows blank commission rate' do
        agent = ReferralAgent.new(name: 'Agent Smith', commission_rate: nil)
        expect(agent).to be_valid
      end

      it 'accepts commission rates between 0 and 100' do
        valid_rates = [0, 0.5, 1, 10, 50, 99.99, 100]

        valid_rates.each do |rate|
          agent = ReferralAgent.new(name: 'Agent Smith', commission_rate: rate)
          expect(agent).to be_valid, "Commission rate #{rate} should be valid"
        end
      end

      it 'rejects negative commission rates' do
        agent = ReferralAgent.new(name: 'Agent Smith', commission_rate: -1)
        expect(agent).not_to be_valid
        expect(agent.errors[:commission_rate]).to be_present
      end

      it 'rejects commission rates over 100' do
        invalid_rates = [100.01, 101, 150, 1000]

        invalid_rates.each do |rate|
          agent = ReferralAgent.new(name: 'Agent Smith', commission_rate: rate)
          expect(agent).not_to be_valid, "Commission rate #{rate} should be invalid"
          expect(agent.errors[:commission_rate]).to be_present
        end
      end
    end
  end

  describe 'attributes' do
    let(:agent) { ReferralAgent.new }

    it 'has name attribute' do
      agent.name = 'John Agent'
      expect(agent.name).to eq('John Agent')
    end

    it 'has email attribute' do
      agent.email = 'agent@example.com'
      expect(agent.email).to eq('agent@example.com')
    end

    it 'has phone attribute' do
      agent.phone = '+63 917 123 4567'
      expect(agent.phone).to eq('+63 917 123 4567')
    end

    it 'has commission_rate attribute' do
      agent.commission_rate = 5.5
      expect(agent.commission_rate).to eq(5.5)
    end
  end

  describe 'edge cases' do
    it 'handles commission rate at exact boundaries' do
      agent_zero = ReferralAgent.new(name: 'Agent Zero', commission_rate: 0)
      agent_hundred = ReferralAgent.new(name: 'Agent Hundred', commission_rate: 100)

      expect(agent_zero).to be_valid
      expect(agent_hundred).to be_valid
    end

    it 'handles decimal precision for commission rates' do
      agent = ReferralAgent.new(name: 'Agent Precise', commission_rate: 12.3456789)
      expect(agent).to be_valid
      agent.save!
      expect(agent.commission_rate).to be_within(0.0001).of(12.3456789)
    end

    it 'handles very small commission rates' do
      agent = ReferralAgent.new(name: 'Agent Tiny', commission_rate: 0.0001)
      expect(agent).to be_valid
    end

    it 'handles commission rate as string input' do
      agent = ReferralAgent.new(name: 'Agent String')
      agent.commission_rate = '15.5'
      expect(agent).to be_valid
      expect(agent.commission_rate).to eq(15.5)
    end
  end

  describe 'loan association' do
    let(:agent) { ReferralAgent.create!(name: 'Test Agent', commission_rate: 5) }
    let(:borrower) { Borrower.create!(name: 'Test Borrower') }

    it 'can have multiple loans' do
      loan1 = Loan.create!(
        borrower: borrower,
        referral_agent: agent,
        amount: 50000,
        interest_rate: 12,
        term_months: 24,
        start_date: Date.today,
        status: 'active'
      )
      loan2 = Loan.create!(
        borrower: borrower,
        referral_agent: agent,
        amount: 100000,
        interest_rate: 10,
        term_months: 36,
        start_date: Date.today,
        status: 'active'
      )

      expect(agent.loans.count).to eq(2)
      expect(agent.loans).to include(loan1, loan2)
    end

    it 'nullifies loan association when deleted' do
      loan = Loan.create!(
        borrower: borrower,
        referral_agent: agent,
        amount: 50000,
        interest_rate: 12,
        term_months: 24,
        start_date: Date.today,
        status: 'active'
      )

      expect(loan.referral_agent).to eq(agent)

      agent.destroy
      loan.reload

      expect(loan.referral_agent).to be_nil
      expect(Loan.exists?(loan.id)).to be_truthy
    end
  end
end