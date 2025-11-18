# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Clear existing data
puts "Clearing existing data..."
Payment.destroy_all
Loan.destroy_all
Borrower.destroy_all
ReferralAgent.destroy_all

# Create Borrowers
puts "Creating borrowers..."
borrowers = [
  Borrower.create!(name: "John Doe", email: "john@example.com", phone: "555-0101", address: "123 Main St, City"),
  Borrower.create!(name: "Jane Smith", email: "jane@example.com", phone: "555-0102", address: "456 Oak Ave, Town"),
  Borrower.create!(name: "Bob Johnson", email: "bob@example.com", phone: "555-0103", address: "789 Pine Rd, Village"),
  Borrower.create!(name: "Alice Williams", email: "alice@example.com", phone: "555-0104", address: "321 Elm St, Borough"),
  Borrower.create!(name: "Charlie Brown", email: "charlie@example.com", phone: "555-0105", address: "654 Maple Dr, County")
]

# Create Referral Agents
puts "Creating referral agents..."
agents = [
  ReferralAgent.create!(name: "Sarah Agent", email: "sarah@agents.com", phone: "555-0201", commission_rate: 5.0),
  ReferralAgent.create!(name: "Mike Broker", email: "mike@brokers.com", phone: "555-0202", commission_rate: 7.5),
  ReferralAgent.create!(name: "Lisa Consultant", email: "lisa@consultants.com", phone: "555-0203", commission_rate: 10.0)
]

# Create Loans (amounts in Philippine Peso)
puts "Creating loans..."
loans = []

# Active loans with referral agents
loans << Loan.create!(
  borrower: borrowers[0],
  referral_agent: agents[0],
  amount: 500000.00,
  interest_rate: 12.0,
  term_months: 12,
  start_date: 6.months.ago,
  status: "active"
)

loans << Loan.create!(
  borrower: borrowers[1],
  referral_agent: agents[1],
  amount: 1250000.00,
  interest_rate: 15.0,
  term_months: 24,
  start_date: 4.months.ago,
  status: "active"
)

loans << Loan.create!(
  borrower: borrowers[2],
  referral_agent: agents[2],
  amount: 250000.00,
  interest_rate: 10.0,
  term_months: 6,
  start_date: 3.months.ago,
  status: "active"
)

# Active loan without referral agent
loans << Loan.create!(
  borrower: borrowers[3],
  referral_agent: nil,
  amount: 750000.00,
  interest_rate: 12.5,
  term_months: 18,
  start_date: 2.months.ago,
  status: "active"
)

# Paid loan
loans << Loan.create!(
  borrower: borrowers[4],
  referral_agent: agents[0],
  amount: 400000.00,
  interest_rate: 10.0,
  term_months: 12,
  start_date: 14.months.ago,
  status: "paid"
)

# Create Payments (amounts in Philippine Peso)
puts "Creating payments..."

# Payments for first loan
Payment.create!(loan: loans[0], amount: 100000.00, payment_date: 5.months.ago, notes: "Initial payment")
Payment.create!(loan: loans[0], amount: 100000.00, payment_date: 3.months.ago, notes: "Second payment")
Payment.create!(loan: loans[0], amount: 75000.00, payment_date: 1.month.ago, notes: "Partial payment")

# Payments for second loan
Payment.create!(loan: loans[1], amount: 250000.00, payment_date: 3.months.ago, notes: "Down payment")
Payment.create!(loan: loans[1], amount: 150000.00, payment_date: 1.month.ago, notes: "Monthly payment")

# Payments for third loan
Payment.create!(loan: loans[2], amount: 50000.00, payment_date: 2.months.ago, notes: "First payment")
Payment.create!(loan: loans[2], amount: 50000.00, payment_date: 1.month.ago, notes: "Second payment")

# Payments for fourth loan
Payment.create!(loan: loans[3], amount: 150000.00, payment_date: 1.month.ago, notes: "Initial payment")

# Full payment for paid loan
Payment.create!(loan: loans[4], amount: 440000.00, payment_date: 2.months.ago, notes: "Full payment with interest")

puts "Seed data created successfully!"
puts "Created #{Borrower.count} borrowers"
puts "Created #{ReferralAgent.count} referral agents"
puts "Created #{Loan.count} loans"
puts "Created #{Payment.count} payments"
