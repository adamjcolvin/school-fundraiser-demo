class AddHeroCopyToCampaigns < ActiveRecord::Migration[7.2]
  def change
    add_column :campaigns, :location, :string, null: false, default: "Lincoln, Nebraska"
    add_column :campaigns, :image_alt, :string, null: false,
      default: "Students gathered at tables in a classroom, listening to their teacher"

    change_column_default :campaigns, :location, from: "Lincoln, Nebraska", to: nil
    change_column_default :campaigns, :image_alt,
      from: "Students gathered at tables in a classroom, listening to their teacher", to: nil
  end
end
