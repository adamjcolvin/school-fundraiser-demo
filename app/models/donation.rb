class Donation < ApplicationRecord
  PAGE_SIZE = 10
  MIN_CENTS = 100
  MAX_CENTS = 10_000_000
  NOTE_LIMIT = 500
  AMOUNT_PATTERN = /\A\d+(\.\d{1,2})?\z/
  PRESETS = [ 25, 50, 100, 250 ].freeze
  DEFAULT_AMOUNT = "50"

  belongs_to :campaign
  has_rich_text :note

  scope :recent, -> { with_rich_text_note.order(created_at: :desc, id: :desc) }

  normalizes :donor_name, with: ->(name) { name.strip }
  normalizes :donor_email, with: ->(email) { email.strip.downcase }

  validates :donor_name, presence: true, length: { maximum: 80 }
  validates :donor_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :amount_cents, numericality: { only_integer: true, in: MIN_CENTS..MAX_CENTS }
  validate :note_is_short_enough

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

  # The value shown in the gift form. A fresh form suggests DEFAULT_AMOUNT.
  # A rejected submission keeps what the donor typed.
  def form_amount
    amount.presence || (errors.any? ? nil : DEFAULT_AMOUNT)
  end

  def preset_selected?(preset)
    value = form_amount
    value.present? && value.to_d == preset.to_d
  end

  def note_text
    note.to_plain_text.strip
  end

  def note?
    note_text.present?
  end

  def publish
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

  # One page of the public gift list, newest first. The cursor is the id of
  # the last gift already shown. The next page is every gift strictly older
  # than that row, so a gift that arrives at the top does not shift the rest.
  class Page
    attr_reader :records, :before

    def initialize(campaign, before = nil)
      @before = before.presence
      scope = campaign.donations.recent

      if (cursor = cursor_for(campaign))
        scope = scope.where(
          "(donations.created_at, donations.id) < (?, ?)",
          cursor.created_at, cursor.id
        )
      end

      batch = scope.limit(PAGE_SIZE + 1).to_a
      @more = batch.size > PAGE_SIZE
      @records = batch.first(PAGE_SIZE)
    end

    def more?
      @more
    end

    def frame_id
      "donations_after_#{before}"
    end

    def next_frame_id
      "donations_after_#{next_before}"
    end

    def next_before
      records.last.id
    end

    private
      def cursor_for(campaign)
        return if before.blank?

        campaign.donations.find_by(id: before)
      end
  end

  private
    def note_is_short_enough
      return if note.to_plain_text.length <= NOTE_LIMIT

      errors.add(:note, :too_long, count: NOTE_LIMIT)
    end
end
