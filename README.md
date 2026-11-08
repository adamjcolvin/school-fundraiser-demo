# Classroom libraries for Oak Street

This is a small school fundraiser I built as a portfolio piece. It is one campaign page. A visitor sees the classroom, the goal and the running total. They can record a gift and watch that total move for everyone who has the page open.

Oak Street Elementary is fictional. The page records gifts. It does not take payment.

One purpose of this project is to be a simple showcase of Rails 7 and Rails 8 technologies. I built it with Rails 8, Ruby 3.2, Postgres and Hotwire. The Rails features section below covers only what this app actually uses.

## What the page does

There is a single campaign. The homepage shows it, and `/campaigns/:id` shows it by id. The photograph, the place line under it and the alt text live on the campaign. The first paragraph of the description is the lede on the progress card, and the rest is the story under the photograph. The layout stays the same if the campaign copy changes.

The gift form asks for a name, an email, an amount and an optional note. The amount starts at $50, with presets for $25, $50, $100 and $250. The presets and the default are constants on `Donation`. The controller builds the new gift with the default, and the template only prints them. Stimulus keeps the highlight in step if you type a custom amount.

The note is Action Text. The editor offers bold and italic, and nothing else.

New gifts are prepended to the list and the progress card is replaced, over a Turbo Stream subscription on the campaign. The list itself loads ten gifts at a time. The next ten are a lazy Turbo Frame whose cursor is the last gift already on the page. The query asks for rows older than that gift's timestamp and id. An offset would slide underneath you as new gifts arrive at the top. A cursor does not.

Saving a gift broadcasts it. Recording one through the form also sends a thank-you email with `deliver_later`. The controller sends it, because the form is the one place a gift arrives from a donor, so seeds and any other plain `create!` do not send mail. Seeds wrap their saves in `Donation.suppressing_turbo_broadcasts`, so they do not broadcast either.

## Rails features

The page is Hotwire. Turbo and Stimulus are the frontend, loaded with importmap, so there is no Node build. `javascript_importmap_tags` in the layout reads `config/importmap.rb`, which pins Turbo, Stimulus, Trix and Action Text. Importmap has been the default JavaScript setup since Rails 7.

**Propshaft.** The stylesheets are plain CSS files in `app/assets/stylesheets`, served with digests by Propshaft. `stylesheet_link_tag :app` in the layout links every one of them. Propshaft is the default asset pipeline in Rails 8.

**Action Text.** The optional note is `has_rich_text :note` on `Donation`, edited with Trix. The toolbar is a `<trix-toolbar>` of my own with bold and italic, which also limits the keyboard shortcuts to those two. A Stimulus controller refuses dropped and pasted files on `trix-file-accept`, and `ActionText::ContentHelper.allowed_tags` keeps the renderer to the tags the editor produces, so pasted headings and links do not reach the page. The saved note is rendered on the gift list.

**Turbo Streams.** `campaigns/show` subscribes with `turbo_stream_from`. `Donation` declares `broadcasts_to` its campaign, which prepends a new gift to the list, and an `after_create_commit` callback replaces the progress card with the new total. Both broadcasts render in a Solid Queue job, not in the request.

**Turbo Frames.** The next page of gifts is a lazy frame. `DonationsController#index` renders it only for a frame request. A normal visit to that URL returns to the campaign. The frame ids come from `dom_id`, so the frame on the page and the frame in the response agree by construction.

**Stimulus.** Three controllers cover the amount presets, the progress bar and the note editor. The submit button needs none: Turbo swaps its label with `data-turbo-submits-with` and marks the form busy while the request is out. The empty state on the gift list needs none either: a CSS `:has()` rule hides it as soon as a gift is on the wall, including one that arrives over the stream.

**Active Storage.** The classroom photograph is `has_one_attached :image` on the campaign. The seed attaches it from `db/seeds/images/classroom.jpg` when the file is missing from disk.

**Solid Queue.** Active Job uses Solid Queue on the primary Postgres database. There is no Redis and no second database. In development and production, Puma loads the Solid Queue plugin in async mode, so the supervisor runs as threads in this process. I went with async because this deploy is one small Render web service. `WEB_CONCURRENCY` stays at 0. The thank-you and the broadcasts go out as jobs. Because a job sits in Postgres, a restart can still send one that had not started. Solid Queue is the default Active Job backend in Rails 8.

**Solid Cable.** Action Cable uses Solid Cable, also on the primary database. The Turbo Stream subscription is delivered by polling that table, so a broadcast reaches every browser connected to the app. Solid Cable is the default Action Cable adapter in Rails 8.

**`normalizes`.** Added in Rails 7.1. The donor name is stripped and the email is stripped and downcased before validation.

**`params.expect`.** Added in Rails 8. The controller reads the gift with `params.expect(donation: [ ... ])`, which permits the fields and rejects a request whose `donation` is not a hash.

**`allow_browser`.** Added in Rails 7.2. `ApplicationController` allows modern browsers and turns the rest away.

**I18n.** Every sentence the page, the flash and the email show is in `config/locales/en.yml`, looked up lazily by view path. Form labels come from the model's attribute names, the submit button from `helpers.submit`, and the mail subject from `default_i18n_subject`. Development and test raise on a missing translation.

## Money

Amounts are integer cents. `$25.50` is `2550`. The form parses dollars with `BigDecimal` and rejects anything that is not a whole number of cents. `ApplicationHelper#money` is the only formatter. The progress card, the gift list, the flash and the email all use it.

The accepted range is $1 to $100,000. That is `numericality: { in: 100..10_000_000 }` on `amount_cents`, with the wording in `config/locales/en.yml`. An invalid amount gets an error that states the whole range.

I made `raised_cents` a `SUM` memoized on the campaign object, rather than a counter column. The progress card reads it several times in one render. A counter column would have to add and subtract cents by hand, and it can drift. The sum is the truth, and the object only lives for the request. The broadcast job loads its own campaign, so the card it renders counts the new gift.

## Accessibility

The page has a skip link to the form. The amount presets are a button group with `aria-pressed`. The progress bar exposes `aria-valuenow`. The gift list is a live region, and form errors sit in an alert. The amount field has a real label, hidden visually because the group already labels it.

## Running it

You need Ruby 3.2.3 and Postgres 14 or newer. The database user needs permission to create databases.

```bash
bin/setup
bin/rails server
```

`bin/setup` installs gems, prepares the database and seeds the campaign. Open http://localhost:3000. `bin/rails server` also starts the job supervisor, so a thank-you email for a gift recorded locally shows up in the log within a second or two.

The seed is safe to run again. It updates the campaign in place, attaches the hero only when the file is missing from disk and inserts the sample gifts only when the campaign has none.

```bash
bin/rails test
bin/rails test:system
bin/rubocop
```

System tests use headless Chrome. They cover recording a gift, validation and the second page of gifts.

## Photograph

The hero is a classroom scene from Unsplash, saved at `db/seeds/images/classroom.jpg`.

Source: https://images.unsplash.com/photo-1509062522246-3755977927d7

License: https://unsplash.com/license
