# A donor note is text with emphasis. The editor offers bold and italic,
# and the renderer keeps only the tags those produce, so pasted headings,
# links and lists do not reach the page.
Rails.application.config.to_prepare do
  ActionText::ContentHelper.allowed_tags = %w[ div br strong em ]
end
