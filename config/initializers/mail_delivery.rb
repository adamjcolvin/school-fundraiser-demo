# Mail is written to the log when SMTP is not configured. Development
# always uses this, and production falls back to it without SMTP_ADDRESS.
ActiveSupport.on_load(:action_mailer) do
  add_delivery_method :log, MailDelivery::Log
end
