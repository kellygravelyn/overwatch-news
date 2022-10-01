# Overwatch News

A super basic script to poll for Overwatch News and post it to Discord via webhook.

## Why?

Blizzard doesn't publish an RSS or Atom feed for their news so if I want real-time updates I have to do this.

## How do I use this?

1. Clone the repo.
2. Run `bundle install`.
3. Run `cp .env.sample .env` to copy the sample.
4. Edit `.env` to have your correct webhook URL.
5. Setup a cron job or something to run the script every once in a while.
