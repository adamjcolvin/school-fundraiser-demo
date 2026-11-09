require "application_system_test_case"

class DonationsTest < ApplicationSystemTestCase
  setup do
    @campaign = campaigns(:oak_street)
    @campaign.image.attach(
      io: File.open(Rails.root.join("db/seeds/images/classroom.jpg")),
      filename: "classroom.jpg",
      content_type: "image/jpeg"
    )
  end

  test "shows the campaign and records a gift" do
    visit root_path

    assert_selector "h1", text: @campaign.title
    assert_selector "img.hero__image[alt='#{@campaign.image_alt}']"
    assert_text @campaign.location
    assert_text "$0.00 raised"
    assert_selector "button[data-trix-attribute='underline']"

    click_button "$100"
    fill_in "Your name", with: "Casey Nguyen"
    fill_in "Email", with: "casey@example.com"
    page.execute_script(<<~JS)
      const editor = document.querySelector("trix-editor")
      editor.editor.insertString("For the kindergarten shelf")
    JS

    click_button "Record this gift"

    assert_text "Thank you, Casey Nguyen. Your gift of $100.00 is recorded."
    assert_text "Casey Nguyen"
    assert_text "For the kindergarten shelf"
    assert_text "$100.00 raised"
    assert_text "50% funded"
  end

  test "saves an underlined note from the toolbar" do
    visit root_path

    fill_in "Your name", with: "June Park"
    fill_in "Email", with: "june@example.com"
    fill_in "Amount (USD)", with: "25"
    page.execute_script(<<~JS)
      const editor = document.querySelector("trix-editor").editor
      editor.activateAttribute("underline")
      editor.insertString("Room 12")
    JS

    click_button "Record this gift"

    assert_selector ".donation__note u", text: "Room 12"
  end

  test "explains an amount that is too small" do
    visit root_path

    fill_in "Your name", with: "Casey Nguyen"
    fill_in "Email", with: "casey@example.com"
    fill_in "Amount (USD)", with: "0.50"
    click_button "Record this gift"

    assert_text "Amount must be between $1 and $100,000"
    assert_no_text "Thank you, Casey Nguyen"
  end

  test "loads the next ten gifts on scroll" do
    11.times do |index|
      @campaign.donations.create!(
        donor_name: format("Donor %02d", index + 1),
        donor_email: "donor#{index}@example.com",
        amount: "20",
        created_at: index.minutes.ago
      )
    end

    visit campaign_path(@campaign)

    assert_text "Donor 01"
    assert_selector "turbo-frame[id^='donations_after_']"
    page.execute_script("document.querySelector(\"turbo-frame[id^='donations_after_']\").scrollIntoView()")

    assert_text "Donor 11"
  end

  test "a normal visit to a later gift page returns to the campaign" do
    visit campaign_donations_path(@campaign, page: 2)

    assert_current_path campaign_path(@campaign)
  end
end
