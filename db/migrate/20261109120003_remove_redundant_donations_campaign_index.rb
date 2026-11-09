class RemoveRedundantDonationsCampaignIndex < ActiveRecord::Migration[7.2]
  def change
    remove_index :donations, :campaign_id, name: "index_donations_on_campaign_id"
  end
end
