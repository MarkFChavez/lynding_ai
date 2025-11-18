json.extract! payment, :id, :loan_id, :amount, :payment_date, :notes, :created_at, :updated_at
json.url payment_url(payment, format: :json)
