# Trix underline is stored as a <u> tag. Action Text's sanitizer allows
# <ins> and not <u>, so an underlined note would disappear on display.
Rails.application.config.to_prepare do
  helper = ActionText::ContentHelper
  helper.allowed_tags = helper.sanitizer.class.allowed_tags + [
    ActionText::Attachment.tag_name,
    "figure",
    "figcaption",
    "u"
  ]
end
