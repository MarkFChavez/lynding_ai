json.extract! loan, :id, :borrower_id, :referral_agent_id, :amount, :interest_rate, :term_months, :start_date, :status, :created_at, :updated_at
json.url loan_url(loan, format: :json)
