class Campaign < ApplicationRecord
  has_many :donations, dependent: :destroy
  has_one_attached :image, dependent: :purge_later

  validates :title, :description, :location, :image_alt, :ends_on, presence: true
  validates :goal_cents, numericality: { only_integer: true, greater_than: 0 }

  # The campaign shown at the root. The app is one fundraiser, so this is
  # the earliest row.
  def self.featured
    order(:id).first
  end

  def raised_cents
    @raised_cents ||= donations.sum(:amount_cents)
  end

  def percent_funded
    return 0 if goal_cents.to_i <= 0

    (raised_cents * 100) / goal_cents
  end

  def percent_bar
    [ percent_funded, 100 ].min
  end

  def goal_reached?
    raised_cents >= goal_cents
  end

  def days_left
    (ends_on - Date.current).to_i
  end

  def ended?
    ends_on < Date.current
  end

  def paragraphs
    description.to_s.strip.split(/\n{2,}/)
  end

  def lede
    paragraphs.first.to_s
  end

  def story_paragraphs
    paragraphs.drop(1)
  end

  def donation_page(before = nil)
    Donation::Page.new(self, before)
  end
end
