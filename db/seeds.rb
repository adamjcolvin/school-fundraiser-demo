# Idempotent. Safe on every deploy.
# Render's free tier wipes local disk, so the hero is reattached when the
# stored file is missing. Sample gifts are inserted once and do not send mail.

HERO = Rails.root.join("db/seeds/images/classroom.jpg")

DESCRIPTION = <<~TEXT
  Fifteen classrooms. A low shelf in each one, filled with books the students pick themselves.

  Oak Street Elementary has one library, down the hall and up the stairs. The youngest grades get there once a week, if the schedule holds.

  This year the PTO is putting a low shelf in every classroom from kindergarten through fifth grade. Each shelf starts with books the teacher and the students pick together, plus a small fund to replace the ones that get loved to pieces.

  The drive covers all fifteen classrooms. Gifts recorded here are a demonstration. No card is charged.
TEXT

GIFTS = [
  { name: "June Park", email: "june.park@example.com", amount: "250", note: "<div>Please write <u>Room 12</u> inside the cover.</div>" },
  { name: "Evan Brooks", email: "evan.brooks@example.com", amount: "50", note: "<div>In honor of <em>Mrs. Alvarez</em>, who never skipped read-aloud.</div>" },
  { name: "Priya Shah", email: "priya.shah@example.com", amount: "100", note: "<div>This one is for the <strong>kindergarten</strong> shelf.</div>" },
  { name: "Luis Ortega", email: "luis.ortega@example.com", amount: "500", note: "<div>Our book club chipped in.</div>" },
  { name: "Naomi Chen", email: "naomi.chen@example.com", amount: "75" },
  { name: "Chris Dalton", email: "chris.dalton@example.com", amount: "100" },
  { name: "Amina Farah", email: "amina.farah@example.com", amount: "25" },
  { name: "Robert Klein", email: "robert.klein@example.com", amount: "200", note: "<div>For the second grade shelf.</div>" },
  { name: "Helen Cho", email: "helen.cho@example.com", amount: "150" },
  { name: "Samira Qureshi", email: "samira.qureshi@example.com", amount: "1000", note: "<div>Put this toward the books the kids pick themselves.</div>" },
  { name: "Patrick Nguyen", email: "patrick.nguyen@example.com", amount: "100" },
  { name: "Grace Ibarra", email: "grace.ibarra@example.com", amount: "75" },
  { name: "Owen Blake", email: "owen.blake@example.com", amount: "40" },
  { name: "The Alvarez family", email: "alvarez.family@example.com", amount: "1500", note: "<div>From our family, for every classroom.</div>" },
  { name: "Dana Whitfield", email: "dana.whitfield@example.com", amount: "100" }
].freeze

def ensure_hero(campaign)
  if campaign.image.attached?
    blob = campaign.image.blob
    return if blob.service.exist?(blob.key)

    campaign.image.attachment.delete
    blob.delete
    campaign.reload
  end

  File.open(HERO, "rb") do |io|
    campaign.image.attach(io: io, filename: "classroom.jpg", content_type: "image/jpeg")
  end
end

def seed_gifts(campaign)
  GIFTS.each_with_index do |gift, index|
    donation = campaign.donations.build(
      donor_name: gift[:name],
      donor_email: gift[:email],
      amount: gift[:amount],
      created_at: (index + 1).days.ago.change(hour: 10)
    )
    donation.note = gift[:note] if gift[:note]
    donation.save!
  end
end

campaign = Campaign.order(:id).first_or_initialize
campaign.assign_attributes(
  title: "Classroom libraries for Oak Street",
  description: DESCRIPTION.strip,
  location: "Lincoln, Nebraska",
  image_alt: "Students gathered at tables in a classroom, listening to their teacher",
  goal_cents: 1_200_000,
  ends_on: Date.new(2027, 5, 15)
)
campaign.save!

ensure_hero(campaign)
seed_gifts(campaign) if campaign.donations.none?
