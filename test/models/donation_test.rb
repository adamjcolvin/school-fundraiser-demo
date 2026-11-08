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

  test "accepts a dollar sign and commas, and reads back what was typed" do
    donation = Donation.new(amount: "$1,250")

    assert_equal 125_000, donation.amount_cents
    assert_equal "$1,250", donation.amount
  end

  test "reads a stored amount back as dollars" do
    donation = @campaign.donations.create!(gift(amount: "20"))

    assert_equal "20.00", Donation.find(donation.id).amount
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
    assert_includes tiny.errors[:amount_cents], "must be between $1 and $100,000"
    assert_includes huge.errors[:amount_cents], "must be between $1 and $100,000"
    assert_includes precise.errors[:amount_cents], "must be a dollar amount, like 25 or 25.00"
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

  test "keeps bold and italic in a donor note" do
    donation = @campaign.donations.create!(gift(note: "<div>For <strong>Room 4</strong>, with <em>thanks</em>.</div>"))

    html = donation.note.body.to_s
    assert_includes html, "<strong>Room 4</strong>"
    assert_includes html, "<em>thanks</em>"
  end

  test "a note with only a line break is blank" do
    blank = build(note: "<div><br></div>")
    written = build(note: "<div>For <em>Room 12</em></div>")

    assert blank.note.blank?
    assert written.note.present?
  end

  test "pages ten gifts at a time, newest first" do
    12.times do |index|
      @campaign.donations.create!(gift(
        donor_name: "Donor #{index}",
        donor_email: "donor#{index}@example.com",
        created_at: index.minutes.ago
      ))
    end

    first = @campaign.donations.page
    second = @campaign.donations.page(after: first.last)

    assert_equal 10, first.length
    assert_equal "Donor 0", first.first.donor_name
    assert_equal [ "Donor 10", "Donor 11" ], second.map(&:donor_name)
  end

  test "older_than keeps gifts that share a timestamp in id order" do
    stamp = Time.zone.parse("2026-06-01 12:00:00")
    older = @campaign.donations.create!(gift(donor_name: "Older", created_at: stamp - 1.hour))
    same_low = @campaign.donations.create!(gift(donor_name: "Same low", created_at: stamp))
    same_high = @campaign.donations.create!(gift(donor_name: "Same high", created_at: stamp))
    newer = @campaign.donations.create!(gift(donor_name: "Newer", created_at: stamp + 1.hour))

    recent = @campaign.donations.recent
    assert_equal [ newer, same_high, same_low, older ].map(&:id), recent.map(&:id)
    assert_equal [ same_low, older ].map(&:id), recent.older_than(same_high).map(&:id)
    assert_equal [ older.id ], recent.older_than(same_low).map(&:id)
  end

  test "a newer gift does not shift gifts after the cursor" do
    12.times do |index|
      @campaign.donations.create!(gift(
        donor_name: "Donor #{index}",
        donor_email: "donor#{index}@example.com",
        created_at: index.minutes.ago
      ))
    end

    cursor = @campaign.donations.page.last
    before_names = @campaign.donations.page(after: cursor).map(&:donor_name)

    @campaign.donations.create!(gift(donor_name: "Newest Gift", created_at: Time.current))

    assert_equal "Newest Gift", @campaign.donations.page.first.donor_name
    assert_equal before_names, @campaign.donations.page(after: cursor).map(&:donor_name)
  end

  test "a new gift is prepended to the list and the progress card is replaced" do
    payloads = capture_turbo_stream_broadcasts([ @campaign, :donations ]) do
      perform_enqueued_jobs(only: Turbo::Streams::ActionBroadcastJob) do
        @campaign.donations.create!(gift(donor_name: "Casey Nguyen"))
      end
    end

    assert_equal [ "prepend", "replace" ], payloads.map { |stream| stream["action"] }
    assert_equal [ "donations", "campaign_progress" ], payloads.map { |stream| stream["target"] }
    assert_includes payloads.first.to_html, "Casey Nguyen"
    assert_includes payloads.second.to_html, "10% funded"
  end

  test "suppressed saves do not broadcast" do
    assert_no_enqueued_jobs(only: Turbo::Streams::ActionBroadcastJob) do
      Donation.suppressing_turbo_broadcasts { @campaign.donations.create!(gift) }
    end
  end

  test "saving a gift does not send mail" do
    assert_no_enqueued_emails do
      @campaign.donations.create!(gift)
    end
  end

  private
    def gift(overrides = {})
      {
        donor_name: "Ada Lovelace",
        donor_email: "ada@example.com",
        amount: "20"
      }.merge(overrides)
    end

    def build(overrides = {})
      @campaign.donations.build(gift(overrides))
    end
end
