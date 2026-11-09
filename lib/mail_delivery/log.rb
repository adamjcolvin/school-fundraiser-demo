module MailDelivery
  # Writes the message to the Rails log when SMTP is not configured.
  class Log
    def initialize(settings = {})
      @settings = settings
    end

    def deliver!(mail)
      logger.info(formatted(mail))
    end

    private
      def logger
        @settings[:logger] || Rails.logger
      end

      def formatted(mail)
        body = mail.text_part ? mail.text_part.decoded : mail.body.decoded

        <<~LOG
          Email logged instead of sent. SMTP is not configured.
          From: #{Array(mail.from).join(", ")}
          To: #{Array(mail.to).join(", ")}
          Subject: #{mail.subject}

          #{body}
        LOG
      end
  end
end
