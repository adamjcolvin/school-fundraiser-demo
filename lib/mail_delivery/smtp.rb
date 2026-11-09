module MailDelivery
  # Settings for Action Mailer's :smtp delivery method, read from the
  # environment. Returns nil when SMTP_ADDRESS is blank so the app can log
  # mail instead.
  class Smtp
    def self.settings(env = ENV)
      new(env).settings
    end

    def initialize(env)
      @env = env
    end

    def settings
      return if address.blank?

      {
        address: address,
        port: port,
        user_name: @env["SMTP_USERNAME"].presence,
        password: @env["SMTP_PASSWORD"],
        authentication: authentication,
        enable_starttls_auto: starttls?
      }
    end

    private
      def address
        @env["SMTP_ADDRESS"].to_s.strip
      end

      def port
        Integer(@env["SMTP_PORT"].presence || 587)
      end

      def authentication
        (@env["SMTP_AUTHENTICATION"].presence || "plain").to_sym
      end

      def starttls?
        raw = @env.fetch("SMTP_ENABLE_STARTTLS_AUTO", "true")
        ActiveModel::Type::Boolean.new.cast(raw)
      end
  end
end
