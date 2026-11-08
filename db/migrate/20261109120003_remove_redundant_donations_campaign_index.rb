class RemoveRedundantDonationsCampaignIndex < ActiveRecord::Migration[8.1]
  def change
    remove_index :donations, :campaign_id, name: "index_donations_on_campaign_id"
  end
end
