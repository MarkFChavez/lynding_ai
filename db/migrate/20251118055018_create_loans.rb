class CreateLoans < ActiveRecord::Migration[8.0]
  def change
    create_table :loans do |t|
      t.references :borrower, null: false, foreign_key: true
      t.references :referral_agent, null: true, foreign_key: true
      t.decimal :amount
      t.decimal :interest_rate
      t.integer :term_months
      t.date :start_date
      t.string :status

      t.timestamps
    end
  end
end
