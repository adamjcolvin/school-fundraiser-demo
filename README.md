# Classroom libraries for Oak Street

A single campaign page for a school fundraiser. Visitors see the classroom, the goal, and the running total, record a gift, and watch the total update live for everyone who has the page open.

Oak Street Elementary is fictional. The page records gifts. It does not collect payment.

## What the page does

- One campaign, with a hero photograph, a goal in dollars, and a progress bar.
- A gift form: name, email, preset or custom amount, and an optional note.
- The note is rich text. Bold, italic, and underline all work.
- New gifts and the new total appear on every open browser without a refresh.
- The gift list loads ten at a time. Scrolling fetches the next ten.
- Each gift queues a thank you email with `deliver_later`.

Money is stored as integer cents. `$25.50` is `2550`.

## Where the Rails features live

| Feature | Where to look |
| --- | --- |
| Turbo Streams | `Donation#publish_donation` broadcasts the new gift and replaces `#campaign_progress`. The page subscribes with `turbo_stream_from` in `campaigns/show`. |
| Turbo Frames | `Donation::Page` pages ten gifts. The first page is in the show view. The next page is a lazy frame rendered by `DonationsController#index`. |
| Stimulus | `amount_picker_controller` (preset amounts), `progress_controller` (bar animation), `donation_form_controller` (submit label), `donation_list_controller` (hides the empty state). |
| Active Storage | `Campaign` `has_one_attached :image`. The file is seeded from `db/seeds/images/classroom.jpg`. |
| Action Mailer | `DonationMailer#thank_you`, called with `deliver_later` from the donation callback. |
| Action Text | `Donation` `has_rich_text :note`. Underline is not in Trix by default. `app/javascript/trix_underline.js` registers the attribute and adds the toolbar button. `config/initializers/action_text.rb` allows the `<u>` tag through the sanitizer. |

Controllers stay thin. Totals, percents, cents conversion, and paging live on `Campaign` and `Donation`.

## Design

The page is a simple nonprofit landing page: a full width classroom photograph, a card with the goal, then the story beside the gift form.

The palette comes from that photograph. Deep green from the room, warm paper from the desks, clay from the maroon hoodie. Type is a serif for titles and a system sans for everything else. Styles are plain CSS, split by component under `app/assets/stylesheets/`. There is no CSS framework.

## Run it locally

Ruby 3.2.3 and Postgres 14 or newer. The app user needs permission to create databases.

```bash
bin/setup
bin/rails server
```

`bin/setup` installs gems, prepares the database, and seeds the campaign. Open [http://localhost:3000](http://localhost:3000).

Seed data is safe to run again. It updates the campaign in place, attaches the hero only when the file is missing from disk, and inserts the sample gifts only when the campaign has none. Sample gifts do not send email.

## Tests

```bash
bin/rails test
bin/rails test:system
```

System tests use headless Chrome. They cover recording a gift, underline in the note, validation, and the second page of gifts.

## Email

There is no SMTP setup. Development and production both use a small delivery method, `MailDelivery::Log`, which writes the message to the Rails log. After you record a gift, the thank you is in the server log, including the recipient and the text body.

The test environment still uses the `:test` delivery method so the suite can assert on the queued message.

`deliver_later` uses the async Active Job adapter. The job runs on a thread in the web process. A restart can drop a job that has not started. That is the tradeoff for not adding a queue gem.

## Deploy on Render

`render.yaml` defines a free web service and a free Postgres database, both in Oregon. Create the service from that Blueprint so Render uses the Ruby runtime rather than the Dockerfile that `rails new` also generates.

Before the first deploy, set `RAILS_MASTER_KEY` in the Render Dashboard. The Blueprint marks it `sync: false`, so Render asks for the value. Locally it is the contents of `config/master.key`. That file is gitignored. Do not commit it. Rails reads `ENV["RAILS_MASTER_KEY"]` in production and uses it to decrypt `config/credentials.yml.enc`.

The Blueprint sets the rest:

- `RAILS_ENV=production`
- `DATABASE_URL` from the Postgres instance (`connectionString`)
- `RAILS_LOG_LEVEL=info`
- `WEB_CONCURRENCY=0`

`bin/render-build.sh` runs `bundle install`, `assets:precompile`, `db:migrate`, and `db:seed`. Migrate and seed are safe to repeat. The health check path is `/up`.

Puma listens on `0.0.0.0` and `$PORT`. It does not fork workers. Turbo Streams use the async Action Cable adapter, which can only reach browsers connected to this process. One free instance and one process is the whole setup. Solid Cable does not ship with Rails 7.2, and Redis is not installed.

### Free tier limits

Checked against Render's current docs:

- The free web service sleeps after about 15 minutes of no traffic. The first request after that is slow.
- A workspace gets 750 free instance hours per month.
- The free Postgres database expires 30 days after creation. There is a grace period, then Render deletes it. A workspace can have one free Postgres database.
- The service disk is ephemeral. Uploads made through the app disappear on redeploy. The hero photograph is committed in the repo and reattached by `db/seeds` during the build, so it survives a new deploy.
- Free web services cannot receive private network traffic. They can reach the database. Outbound SMTP ports are blocked, which is another reason mail is logged.

If the first build fails because the database is not ready yet, redeploy once the Postgres instance is available.

## Photograph

The hero is a classroom scene from Unsplash, saved at `db/seeds/images/classroom.jpg`.

Source: `https://images.unsplash.com/photo-1509062522246-3755977927d7`

License: [Unsplash License](https://unsplash.com/license)

## Notes

- `rails action_text:install` turns on the `image_processing` gem. This app leaves it commented out. The hero is displayed at its original size, and the briefing stays on the gems from `rails new`.
- Brakeman reports that Ruby 3.2 and Rails 7.2 are past upstream support. The demo is pinned to Rails 7.2.4 on purpose. CI skips those two end of life checks and still runs the rest of the scan.
- Rails 7.2 generates a Dockerfile for Kamal. Render should use `render.yaml` (`runtime: ruby`), not that Dockerfile. The Docker entrypoint also migrates and seeds, if you run the image yourself.
