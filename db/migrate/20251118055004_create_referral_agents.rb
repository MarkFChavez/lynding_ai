class CreateReferralAgents < ActiveRecord::Migration[8.0]
  def change
    create_table :referral_agents do |t|
      t.string :name
      t.string :email
      t.string :phone
      t.decimal :commission_rate

      t.timestamps
    end
  end
end
