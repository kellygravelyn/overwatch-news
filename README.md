# Overwatch News

A super basic scripts to poll for Overwatch related stuff and post it to Discord via webhook.

## Why?

Blizzard doesn't publish an RSS or Atom feed for their news so if I want real-time updates I have to do this. And since I did this for news I'm going to do it for other stuff like Twitter.

## How do I use this?

1. Clone the repo.
2. Run `bundle install`.
3. Run `cp .env.sample .env` to copy the sample.
4. Edit `.env` to have your correct values.
5. Setup some cron jobs or something to run `main.sh` or the individual scripts if you only want some of the stuff.
