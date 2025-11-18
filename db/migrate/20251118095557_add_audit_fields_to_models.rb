class AddAuditFieldsToModels < ActiveRecord::Migration[8.0]
  def change
    add_reference :loans, :created_by, foreign_key: { to_table: :users }, null: true
    add_reference :loans, :updated_by, foreign_key: { to_table: :users }, null: true

    add_reference :payments, :created_by, foreign_key: { to_table: :users }, null: true
    add_reference :payments, :updated_by, foreign_key: { to_table: :users }, null: true

    add_reference :borrowers, :created_by, foreign_key: { to_table: :users }, null: true
    add_reference :borrowers, :updated_by, foreign_key: { to_table: :users }, null: true

    add_reference :referral_agents, :created_by, foreign_key: { to_table: :users }, null: true
    add_reference :referral_agents, :updated_by, foreign_key: { to_table: :users }, null: true
  end
end
