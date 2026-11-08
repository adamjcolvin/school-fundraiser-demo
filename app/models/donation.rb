class Donation < ApplicationRecord
  PAGE_SIZE = 10
  MIN_CENTS = 100
  MAX_CENTS = 10_000_000
  NOTE_LIMIT = 500
  AMOUNT_PATTERN = /\A\d+(\.\d{1,2})?\z/

  # Whole dollars offered on the form. The default is selected to start.
  SUGGESTED_AMOUNTS = [ 25, 50, 100, 250 ].freeze
  DEFAULT_AMOUNT = 50

  belongs_to :campaign
  has_rich_text :note

  normalizes :donor_name, with: ->(name) { name.strip }
  normalizes :donor_email, with: ->(email) { email.strip.downcase }

  validates :donor_name, presence: true, length: { maximum: 80 }
  validates :donor_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :amount_cents, numericality: { only_integer: true, in: MIN_CENTS..MAX_CENTS }
  validate :note_is_short_enough

  scope :recent, -> { with_rich_text_note.order(created_at: :desc, id: :desc) }
  scope :older_than, ->(donation) {
    where("(donations.created_at, donations.id) < (?, ?)", donation.created_at, donation.id)
  }

  # A new gift is prepended to the list on every open page, and the
  # progress card is replaced with the campaign's new total. Both render
  # in a job. Seeds wrap their saves in suppressing_turbo_broadcasts.
  broadcasts_to ->(donation) { [ donation.campaign, :donations ] }, inserts_by: :prepend
  after_create_commit :broadcast_progress

  # Newest first, ten at a time. Pass the last gift already on the page to
  # get the ten before it. A cursor holds still when new gifts arrive at
  # the top, where an offset would slide.
  def self.page(after: nil)
    gifts = recent.limit(PAGE_SIZE)
    after ? gifts.older_than(after) : gifts
  end

  # Dollars in, integer cents out. "$1,250.50" is 125050. Anything that is
  # not a whole number of cents comes back nil, and validation explains.
  def self.cents_from(dollars)
    raw = dollars.to_s.strip.delete("$,")
    return unless raw.match?(AMOUNT_PATTERN)

    (BigDecimal(raw) * 100).to_i
  end

  # Reads back what the donor typed, or the stored cents as dollars.
  def amount
    @amount_input || (amount_cents && format("%.2f", amount_cents / 100.0))
  end

  def amount=(dollars)
    @amount_input = dollars.to_s.strip
    self.amount_cents = self.class.cents_from(dollars)
  end

  private
    def broadcast_progress
      broadcast_replace_later_to campaign, :donations,
        target: "campaign_progress", partial: "campaigns/progress", locals: { campaign: campaign }
    end

    def note_is_short_enough
      return if note.to_plain_text.length <= NOTE_LIMIT

      errors.add(:note, :too_long, count: NOTE_LIMIT)
    end
end
