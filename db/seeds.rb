# Idempotent. Safe on every deploy.
# Render's free tier wipes local disk, so the hero is reattached when the
# stored file is missing. Sample gifts are inserted once. They are not
# broadcast and they do not send mail.

HERO = Rails.root.join("db/seeds/images/classroom.jpg")

DESCRIPTION = <<~TEXT
  Fifteen classrooms. A low shelf in each one, filled with books the students pick themselves.

  Oak Street Elementary has one library, down the hall and up the stairs. The youngest grades get there once a week, if the schedule holds.

  This year the PTO is putting a low shelf in every classroom from kindergarten through fifth grade. Each shelf starts with books the teacher and the students pick together, plus a small fund to replace the ones that get loved to pieces.

  The drive covers all fifteen classrooms. Gifts recorded here are a demonstration. No card is charged.
TEXT

GIFTS = [
  { donor_name: "June Park", donor_email: "june.park@example.com", amount: "250", note: "<div>Please write <em>Room 12</em> inside the cover.</div>" },
  { donor_name: "Evan Brooks", donor_email: "evan.brooks@example.com", amount: "50", note: "<div>In honor of <em>Mrs. Alvarez</em>, who never skipped read-aloud.</div>" },
  { donor_name: "Priya Shah", donor_email: "priya.shah@example.com", amount: "100", note: "<div>This one is for the <strong>kindergarten</strong> shelf.</div>" },
  { donor_name: "Luis Ortega", donor_email: "luis.ortega@example.com", amount: "500", note: "<div>Our book club chipped in.</div>" },
  { donor_name: "Naomi Chen", donor_email: "naomi.chen@example.com", amount: "75" },
  { donor_name: "Chris Dalton", donor_email: "chris.dalton@example.com", amount: "100" },
  { donor_name: "Amina Farah", donor_email: "amina.farah@example.com", amount: "25" },
  { donor_name: "Robert Klein", donor_email: "robert.klein@example.com", amount: "200", note: "<div>For the second grade shelf.</div>" },
  { donor_name: "Helen Cho", donor_email: "helen.cho@example.com", amount: "150" },
  { donor_name: "Samira Qureshi", donor_email: "samira.qureshi@example.com", amount: "1000", note: "<div>Put this toward the books the kids pick themselves.</div>" },
  { donor_name: "Patrick Nguyen", donor_email: "patrick.nguyen@example.com", amount: "100" },
  { donor_name: "Grace Ibarra", donor_email: "grace.ibarra@example.com", amount: "75" },
  { donor_name: "Owen Blake", donor_email: "owen.blake@example.com", amount: "40" },
  { donor_name: "The Alvarez family", donor_email: "alvarez.family@example.com", amount: "1500", note: "<div>From our family, for every classroom.</div>" },
  { donor_name: "Dana Whitfield", donor_email: "dana.whitfield@example.com", amount: "100" }
].freeze

def ensure_hero(campaign)
  image = campaign.image
  image.purge if image.attached? && !image.blob.service.exist?(image.blob.key)
  return if image.attached?

  HERO.open("rb") do |file|
    image.attach(io: file, filename: HERO.basename.to_s, content_type: "image/jpeg")
  end
end

def seed_gifts(campaign)
  Donation.suppressing_turbo_broadcasts do
    GIFTS.each_with_index do |gift, index|
      campaign.donations.create!(gift.merge(created_at: (index + 1).days.ago.change(hour: 10)))
    end
  end
end

campaign = Campaign.first_or_initialize
campaign.update!(
  title: "Classroom libraries for Oak Street",
  description: DESCRIPTION.strip,
  location: "Lincoln, Nebraska",
  image_alt: "Students gathered at tables in a classroom, listening to their teacher",
  goal_cents: 1_200_000,
  ends_on: Date.new(2027, 5, 15)
)

ensure_hero(campaign)
seed_gifts(campaign) if campaign.donations.none?
