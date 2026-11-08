class CreateDonations < ActiveRecord::Migration[8.1]
  def change
    create_table :donations do |t|
      t.references :campaign, null: false, foreign_key: true
      t.string :donor_name, null: false
      t.string :donor_email, null: false
      t.integer :amount_cents, null: false

      t.timestamps
    end

    add_index :donations, [ :campaign_id, :created_at, :id ], name: "index_donations_on_campaign_and_recency"
  end
end
