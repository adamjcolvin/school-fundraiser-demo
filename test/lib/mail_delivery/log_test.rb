require "test_helper"

module MailDelivery
  class LogTest < ActiveSupport::TestCase
    test "writes the message to the logger instead of sending it" do
      log = StringIO.new
      mail = ApplicationMailer.new.mail(to: "casey@example.com", subject: "Thank you", body: "Hello Casey")

      Log.new(logger: Logger.new(log)).deliver!(mail)

      assert_match "Email logged instead of sent", log.string
      assert_match "From: gifts@oakstreet.example", log.string
      assert_match "To: casey@example.com", log.string
      assert_match "Subject: Thank you", log.string
      assert_match "Hello Casey", log.string
    end
  end
end
