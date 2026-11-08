require "test_helper"

class DonationTest < ActiveSupport::TestCase
  setup do
    @campaign = campaigns(:oak_street)
  end

  test "stores a dollar amount as integer cents" do
    donation = Donation.new(amount: "25.50")

    assert_equal 2_550, donation.amount_cents
    assert_equal "25.50", donation.amount
  end

  test "accepts a dollar sign and commas" do
    donation = Donation.new(amount: "$1,250")

    assert_equal 125_000, donation.amount_cents
  end

  test "rejects a blank, tiny, huge, or imprecise amount" do
    blank = build(amount: "")
    tiny = build(amount: "0.50")
    huge = build(amount: "100000.01")
    precise = build(amount: "10.999")

    assert_not blank.valid?
    assert_not tiny.valid?
    assert_not huge.valid?
    assert_not precise.valid?
    assert_includes tiny.errors[:amount], "must be at least $1"
    assert_includes precise.errors[:amount], "must be a dollar amount, like 25 or 25.00"
  end

  test "requires a name and a real email" do
    donation = build(donor_name: "  ", donor_email: "not-an-email")

    assert_not donation.valid?
    assert_includes donation.errors[:donor_name], "can't be blank"
    assert_includes donation.errors[:donor_email], "must be a real email address"
  end

  test "downcases the email and strips the name" do
    donation = build(donor_name: "  Casey Nguyen  ", donor_email: "Casey@Example.com")
    donation.validate

    assert_equal "Casey Nguyen", donation.donor_name
    assert_equal "casey@example.com", donation.donor_email
  end

  test "limits the note to 500 characters" do
    donation = build(note: "a" * 501)

    assert_not donation.valid?
    assert_match "too long", donation.errors[:note].to_sentence
  end

  test "keeps bold, italic, and underline in a donor note" do
    donation = @campaign.donations.create!(gift.merge(
      note: "<div>For <strong>Room 4</strong>, with <em>thanks</em> and <u>care</u>.</div>"
    ))

    html = donation.note.body.to_s
    assert_includes html, "<strong>Room 4</strong>"
    assert_includes html, "<em>thanks</em>"
    assert_includes html, "<u>care</u>"
  end

  test "pages gifts ten at a time, newest first" do
    12.times do |index|
      @campaign.donations.create!(gift.merge(
        donor_name: "Donor #{index}",
        donor_email: "donor#{index}@example.com",
        created_at: index.minutes.ago
      ))
    end

    first = @campaign.donation_page(1)
    second = @campaign.donation_page(2)

    assert_equal 10, first.records.length
    assert first.more?
    assert_equal "Donor 0", first.records.first.donor_name
    assert_equal 2, second.records.length
    assert_not second.more?
    assert_equal "donations_page_2", "donations_page_#{first.next_number}"
  end

  test "broadcasts the gift and the total and queues a thank you" do
    donation = nil

    assert_enqueued_emails 1 do
      payloads = capture_turbo_stream_broadcasts([ @campaign, :donations ]) do
        donation = @campaign.donations.create!(gift.merge(skip_notifications: false, donor_name: "Casey Nguyen"))
      end

      assert_equal [ "prepend", "replace" ], payloads.map { |stream| stream["action"] }
      assert_equal [ "donations", "campaign_progress" ], payloads.map { |stream| stream["target"] }
      assert_includes payloads.first.to_html, "Casey Nguyen"
      assert_includes payloads.second.to_html, "10% funded"
    end

    assert_enqueued_email_with DonationMailer, :thank_you, args: [ donation ]
  end

  test "a quiet save skips the broadcast and the email" do
    assert_no_enqueued_emails do
      assert_no_turbo_stream_broadcasts([ @campaign, :donations ]) do
        @campaign.donations.create!(gift)
      end
    end
  end

  private
    def gift
      {
        donor_name: "Ada Lovelace",
        donor_email: "ada@example.com",
        amount: "20",
        skip_notifications: true
      }
    end

    def build(overrides = {})
      @campaign.donations.build(gift.merge(overrides))
    end
end
