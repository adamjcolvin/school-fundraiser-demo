# Classroom libraries for Oak Street

This is a small school fundraiser I built as a portfolio piece. It is one campaign page. A visitor sees the classroom, the goal and the running total. They can record a gift and watch that total move for everyone who has the page open.

Oak Street Elementary is fictional. The page records gifts. It does not take payment.

I built it on the stack the role uses, Rails 7 and Postgres. Specifically, it runs Rails 7.2 and Ruby 3.2 on Postgres, with Hotwire for the frontend.

## What the page does

There is a single campaign. The homepage shows it, and `/campaigns/:id` shows it by id. The photograph, the place line under it and the alt text live on the campaign. The layout stays the same if the campaign copy changes.

The gift form asks for a name, an email, an amount and an optional note. The amount starts at $50, with presets for $25, $50, $100 and $250. Those numbers, the default and which preset is selected sit on `Donation`, so the template only prints them. Stimulus keeps the highlight in step if you type a custom amount.

The note is Action Text. Trix does not ship underline, so `app/javascript/trix_underline.js` registers it once, on `trix-before-initialize`, and the Action Text sanitizer allows the `<u>` tag.

New gifts are prepended to the list and the progress card is replaced, over a Turbo Stream subscription on the campaign. The list itself loads ten gifts at a time. The next ten are a lazy Turbo Frame whose cursor is the id of the last gift already on the page. The query asks for rows older than that gift's timestamp and id. An offset would slide underneath you as new gifts arrive at the top. A cursor does not.

Recording a gift sends a thank-you email with `deliver_later`. Seeds and any other plain `create!` do not. I put that in the controller, which is what publishes the gift, so there is no flag to remember to set.

## Money

Amounts are integer cents. `$25.50` is `2550`. The form parses dollars with `BigDecimal` and half-up rounding, and it rejects anything that is not a whole number of cents. `ApplicationHelper#money` is the only formatter. The progress card, the gift list, the flash and the email all use it.

The accepted range is $1 to $100,000. That is `numericality: { in: 100..10_000_000 }` on `amount_cents`, with the wording in `config/locales/en.yml`. An invalid amount gets an error that states the whole range.

I made `raised_cents` a `SUM` memoized on the campaign object, rather than a counter column. The progress card reads it several times in one render. A counter column would have to add and subtract cents by hand, and it can drift. The sum is the truth, and the object only lives for the request.

## Jobs and live updates

I used Solid Queue for Active Job and Solid Cable for Action Cable, and both use the primary Postgres database. Redis would be a second service to run, and a separate queue database would be a second schema against the one Render Postgres instance. The queue tables and `solid_cable_messages` are ordinary migrations, so `bin/render-build.sh` picks them up with `db:migrate`.

Puma loads the Solid Queue plugin in every environment except test, and runs it in async mode. The supervisor, the dispatcher, the worker and the recurring cleanup are threads in the web process. Fork mode is the gem's default, and it is the better-isolated setup, but it also starts a separate process for each of those roles. I went with async because this deploy is one small Render web service. Threads keep the memory in one process, which is the difference between the service staying up and it being killed. `WEB_CONCURRENCY` stays at 0 for the same reason. `bin/jobs` is there if you want the supervisor on its own.

Because the jobs sit in Postgres, a restart still sends a thank-you email that had not started yet. The old in-process async adapter couldn't do that. The database pool is `RAILS_MAX_THREADS` plus eight, so the web threads and the queue threads are not sharing too few connections.

In production and development the queue adapter waits until an open transaction commits before it enqueues. The test suite leaves the default alone, so `assert_enqueued_emails` still sees the job inside the test transaction. The controller enqueues after `save` has returned, so a gift that fails validation never sends mail.

Solid Cable polls the same database. A message written on this process reaches a browser connected to any process. That matters if the service is ever more than one instance. The async Cable adapter only talks to browsers on the same process, which is a trap the moment you add a second one.

## Mail

`SMTP_ADDRESS` turns delivery on. The settings are `SMTP_PORT`, `SMTP_USERNAME`, `SMTP_PASSWORD`, `SMTP_AUTHENTICATION`, and `SMTP_ENABLE_STARTTLS_AUTO`. Port 587, plain auth and STARTTLS are the defaults when those three are absent. A failed delivery raises.

When `SMTP_ADDRESS` is blank, the message is written to the log by `MailDelivery::Log`. Development always logs. Test uses the `:test` delivery method. The log delivery method is registered in `config/initializers/mail_delivery.rb`.

## Accessibility

The page has a skip link to the form. The amount presets are a button group with `aria-pressed`. The progress bar exposes `aria-valuenow`. The gift list is a live region, and form errors sit in an alert. The amount field has a real label, hidden visually because the group already labels it.

## Running it

Ruby 3.2.3 and Postgres 14 or newer. The database user needs permission to create databases.

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

System tests use headless Chrome. They cover recording a gift, underline in the note, validation and the second page of gifts.

## Deploying on Render

`render.yaml` defines a web service and a Postgres database, both in Oregon. Create the service from that Blueprint. Render then uses the Ruby runtime. The Dockerfile from `rails new` is for Kamal, and it is the wrong build for this service.

Before the first deploy, set `RAILS_MASTER_KEY` in the Render dashboard. The Blueprint marks it `sync: false`, so Render asks for the value. Locally it is the contents of `config/master.key`. That file is gitignored. Rails reads `ENV["RAILS_MASTER_KEY"]` in production and uses it to decrypt `config/credentials.yml.enc`.

The Blueprint sets `RAILS_ENV`, `DATABASE_URL` from the database, `RAILS_LOG_LEVEL` and `WEB_CONCURRENCY=0`. Set the SMTP variables on the service as well. `APP_HOST` is optional. The mailer falls back to `example.com` for links.

`bin/render-build.sh` runs `bundle install`, `assets:precompile`, `db:migrate` and `db:seed`. Migrate and seed are safe to repeat. Puma listens on `0.0.0.0` and `$PORT`. The health check is `/up`.

The free web service sleeps after about fifteen minutes of no traffic, and the first request after that is slow. A workspace gets 750 free instance hours a month. The service disk is ephemeral, so uploads made through the app disappear on redeploy. The hero photograph is in the repo and the seed reattaches it during the build.

## Photograph

The hero is a classroom scene from Unsplash, saved at `db/seeds/images/classroom.jpg`.

Source: https://images.unsplash.com/photo-1509062522246-3755977927d7

License: https://unsplash.com/license

## Notes

`rails action_text:install` turns on the `image_processing` gem. I left it commented out. The hero is displayed at its original size.

Brakeman reports that Ruby 3.2 and Rails 7.2 are past upstream support. The demo is pinned to Rails 7.2.4 on purpose. CI skips those two end-of-life checks and still runs the rest of the scan.

Rails 7.2 generates a Dockerfile for Kamal. Render should use `render.yaml` (`runtime: ruby`), not that Dockerfile. The Docker entrypoint also migrates and seeds, if you run the image yourself.
