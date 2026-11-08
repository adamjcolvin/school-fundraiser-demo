class ApplicationMailer < ActionMailer::Base
  default from: "Oak Street Elementary PTO <gifts@oakstreet.example>"
  helper ApplicationHelper
  layout "mailer"
end
