class CreateInstallmentPayments < ActiveRecord::Migration[8.0]
  def change
    create_table :installment_payments do |t|
      t.references :installment, null: false, foreign_key: true
      t.references :payment, null: false, foreign_key: true
      t.decimal :amount_applied, precision: 10, scale: 2, null: false

      t.timestamps

      t.index [:installment_id, :payment_id], unique: true
    end
  end
end
