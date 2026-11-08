class CreateCampaigns < ActiveRecord::Migration[7.2]
  def change
    create_table :campaigns do |t|
      t.string :title, null: false
      t.text :description, null: false
      t.integer :goal_cents, null: false
      t.date :ends_on, null: false

      t.timestamps
    end
  end
end
