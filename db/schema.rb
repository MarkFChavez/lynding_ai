# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_11_18_095557) do
  create_table "borrowers", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.string "phone"
    t.text "address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "created_by_id"
    t.integer "updated_by_id"
    t.index ["created_by_id"], name: "index_borrowers_on_created_by_id"
    t.index ["updated_by_id"], name: "index_borrowers_on_updated_by_id"
  end

  create_table "installment_payments", force: :cascade do |t|
    t.integer "installment_id", null: false
    t.integer "payment_id", null: false
    t.decimal "amount_applied", precision: 10, scale: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["installment_id", "payment_id"], name: "index_installment_payments_on_installment_id_and_payment_id", unique: true
    t.index ["installment_id"], name: "index_installment_payments_on_installment_id"
    t.index ["payment_id"], name: "index_installment_payments_on_payment_id"
  end

  create_table "installments", force: :cascade do |t|
    t.integer "loan_id", null: false
    t.integer "installment_number", null: false
    t.decimal "principal_amount", precision: 10, scale: 2, null: false
    t.decimal "interest_amount", precision: 10, scale: 2, null: false
    t.decimal "total_amount", precision: 10, scale: 2, null: false
    t.date "due_date", null: false
    t.string "status", default: "pending", null: false
    t.decimal "amount_paid", precision: 10, scale: 2, default: "0.0"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["due_date"], name: "index_installments_on_due_date"
    t.index ["loan_id", "installment_number"], name: "index_installments_on_loan_id_and_installment_number", unique: true
    t.index ["loan_id"], name: "index_installments_on_loan_id"
    t.index ["status"], name: "index_installments_on_status"
  end

  create_table "loans", force: :cascade do |t|
    t.integer "borrower_id", null: false
    t.integer "referral_agent_id"
    t.decimal "amount"
    t.decimal "interest_rate"
    t.integer "term_months"
    t.date "start_date"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "created_by_id"
    t.integer "updated_by_id"
    t.index ["borrower_id"], name: "index_loans_on_borrower_id"
    t.index ["created_by_id"], name: "index_loans_on_created_by_id"
    t.index ["referral_agent_id"], name: "index_loans_on_referral_agent_id"
    t.index ["updated_by_id"], name: "index_loans_on_updated_by_id"
  end

  create_table "payments", force: :cascade do |t|
    t.integer "loan_id", null: false
    t.decimal "amount"
    t.date "payment_date"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "created_by_id"
    t.integer "updated_by_id"
    t.index ["created_by_id"], name: "index_payments_on_created_by_id"
    t.index ["loan_id"], name: "index_payments_on_loan_id"
    t.index ["updated_by_id"], name: "index_payments_on_updated_by_id"
  end

  create_table "referral_agents", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.string "phone"
    t.decimal "commission_rate"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "created_by_id"
    t.integer "updated_by_id"
    t.index ["created_by_id"], name: "index_referral_agents_on_created_by_id"
    t.index ["updated_by_id"], name: "index_referral_agents_on_updated_by_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.string "role", default: "owner", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "borrowers", "users", column: "created_by_id"
  add_foreign_key "borrowers", "users", column: "updated_by_id"
  add_foreign_key "installment_payments", "installments"
  add_foreign_key "installment_payments", "payments"
  add_foreign_key "installments", "loans"
  add_foreign_key "loans", "borrowers"
  add_foreign_key "loans", "referral_agents"
  add_foreign_key "loans", "users", column: "created_by_id"
  add_foreign_key "loans", "users", column: "updated_by_id"
  add_foreign_key "payments", "loans"
  add_foreign_key "payments", "users", column: "created_by_id"
  add_foreign_key "payments", "users", column: "updated_by_id"
  add_foreign_key "referral_agents", "users", column: "created_by_id"
  add_foreign_key "referral_agents", "users", column: "updated_by_id"
  add_foreign_key "sessions", "users"
end
