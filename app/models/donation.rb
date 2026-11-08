class Donation < ApplicationRecord
  PAGE_SIZE = 10
  MIN_CENTS = 100
  MAX_CENTS = 10_000_000
  NOTE_LIMIT = 500
  AMOUNT_PATTERN = /\A\d+(\.\d{1,2})?\z/

  belongs_to :campaign
  has_rich_text :note

  # Set by seeds so sample gifts do not email anyone or broadcast.
  attribute :skip_notifications, :boolean, default: false

  scope :recent, -> { with_rich_text_note.order(created_at: :desc, id: :desc) }

  before_validation :normalize_donor_fields

  validates :donor_name, presence: true, length: { maximum: 80 }
  validates :donor_email, presence: true,
    format: { with: URI::MailTo::EMAIL_REGEXP, message: "must be a real email address" }
  validate :amount_is_acceptable
  validate :note_is_short_enough

  after_create_commit :publish_donation, unless: :skip_notifications

  def self.human_attribute_name(attribute, options = {})
    { donor_name: "Name", donor_email: "Email", amount: "Amount", note: "Note" }[attribute.to_sym] || super
  end

  def self.cents_from(value)
    raw = value.to_s.strip.delete("$,")
    return if raw.blank?
    return unless raw.match?(AMOUNT_PATTERN)

    (BigDecimal(raw) * 100).round(0, BigDecimal::ROUND_HALF_UP).to_i
  end

  def amount
    if !amount_cents.nil?
      format("%.2f", amount_cents / 100.0)
    elsif defined?(@amount_input)
      @amount_input
    end
  end

  def amount=(value)
    @amount_input = value.to_s.strip
    self.amount_cents = self.class.cents_from(value)
  end

  # One page of the public gift list. The first page is rendered with the
  # campaign. Later pages arrive through a lazy Turbo Frame.
  class Page
    attr_reader :records, :number

    def initialize(campaign, page)
      @number = page.to_i
      @number = 1 if @number < 1

      batch = campaign.donations.recent.offset((@number - 1) * PAGE_SIZE).limit(PAGE_SIZE + 1).to_a
      @more = batch.size > PAGE_SIZE
      @records = batch.first(PAGE_SIZE)
    end

    def more?
      @more
    end

    def next_number
      @number + 1
    end
  end

  private
    def normalize_donor_fields
      self.donor_name = donor_name.to_s.strip
      self.donor_email = donor_email.to_s.strip.downcase
    end

    def amount_is_acceptable
      if amount_cents.nil?
        errors.add(:amount, "must be a dollar amount, like 25 or 25.00")
      elsif amount_cents < MIN_CENTS
        errors.add(:amount, "must be at least $1")
      elsif amount_cents > MAX_CENTS
        errors.add(:amount, "must be $100,000 or less")
      end
    end

    def note_is_short_enough
      return if note.to_plain_text.length <= NOTE_LIMIT

      errors.add(:note, "is too long (#{NOTE_LIMIT} characters at most)")
    end

    def publish_donation
      broadcast_prepend_to(
        campaign,
        :donations,
        target: "donations",
        partial: "donations/donation",
        locals: { donation: self }
      )

      broadcast_replace_to(
        campaign,
        :donations,
        target: "campaign_progress",
        partial: "campaigns/progress",
        locals: { campaign: campaign }
      )

      DonationMailer.thank_you(self).deliver_later
    end
end
