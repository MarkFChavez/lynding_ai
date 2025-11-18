json.extract! borrower, :id, :name, :email, :phone, :address, :created_at, :updated_at
json.url borrower_url(borrower, format: :json)
