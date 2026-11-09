require_relative "../../lib/mail_delivery/log"

ActionMailer::Base.add_delivery_method :log, MailDelivery::Log
