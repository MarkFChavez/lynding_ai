class CreateInstallments < ActiveRecord::Migration[8.0]
  def change
    create_table :installments do |t|
      t.references :loan, null: false, foreign_key: true
      t.integer :installment_number, null: false
      t.decimal :principal_amount, precision: 10, scale: 2, null: false
      t.decimal :interest_amount, precision: 10, scale: 2, null: false
      t.decimal :total_amount, precision: 10, scale: 2, null: false
      t.date :due_date, null: false
      t.string :status, default: 'pending', null: false
      t.decimal :amount_paid, precision: 10, scale: 2, default: 0

      t.timestamps

      t.index [:loan_id, :installment_number], unique: true
      t.index :due_date
      t.index :status
    end
  end
end
