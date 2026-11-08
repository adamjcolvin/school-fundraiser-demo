class Campaign < ApplicationRecord
  has_many :donations, dependent: :destroy
  has_one_attached :image

  validates :title, :description, :location, :image_alt, :ends_on, presence: true
  validates :goal_cents, numericality: { only_integer: true, greater_than: 0 }

  # The campaign shown at the root. The app is one fundraiser, so this is
  # the earliest row.
  def self.featured
    first
  end

  # The first paragraph of the description introduces the campaign. The
  # rest is the story told under the photograph.
  def lede
    paragraphs.first.to_s
  end

  def story
    paragraphs.drop(1).join("\n\n")
  end

  def raised_cents
    @raised_cents ||= donations.sum(:amount_cents)
  end

  def percent_funded
    return 0 unless goal_cents&.positive?

    (raised_cents * 100) / goal_cents
  end

  # The share of the goal the progress bar shows. It stops at 100.
  def percent_complete
    percent_funded.clamp(0, 100)
  end

  def goal_reached?
    raised_cents >= goal_cents
  end

  def days_left
    (ends_on - Date.current).to_i
  end

  def ended?
    ends_on.past?
  end

  private
    def paragraphs
      description.to_s.strip.split(/\n{2,}/)
    end
end
