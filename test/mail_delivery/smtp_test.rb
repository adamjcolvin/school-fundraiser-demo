require "test_helper"
require "mail_delivery/smtp"

class MailDeliverySmtpTest < ActiveSupport::TestCase
  test "reads the smtp settings from the environment" do
    settings = MailDelivery::Smtp.settings(
      "SMTP_ADDRESS" => "smtp.example.com",
      "SMTP_PORT" => "2525",
      "SMTP_USERNAME" => "gifts",
      "SMTP_PASSWORD" => "secret",
      "SMTP_AUTHENTICATION" => "login",
      "SMTP_ENABLE_STARTTLS_AUTO" => "false"
    )

    assert_equal({
      address: "smtp.example.com",
      port: 2525,
      user_name: "gifts",
      password: "secret",
      authentication: :login,
      enable_starttls_auto: false
    }, settings)
  end

  test "defaults the port, authentication, and starttls" do
    settings = MailDelivery::Smtp.settings("SMTP_ADDRESS" => "smtp.example.com")

    assert_equal 587, settings[:port]
    assert_equal :plain, settings[:authentication]
    assert settings[:enable_starttls_auto]
  end

  test "is absent without an address" do
    assert_nil MailDelivery::Smtp.settings({})
    assert_nil MailDelivery::Smtp.settings("SMTP_ADDRESS" => "  ")
  end
end
