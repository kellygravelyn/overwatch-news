# Overwatch News

A set of scripts to poll for Overwatch related stuff and post it to Discord via webhook.

## Why?

I have an #overwatch channel in Discord where I'd like to have all Overwatch related news show up so I can discuss it with my brother. These scripts handle doing that for all the stuff I find interesting.

## How do I use this?

1. Clone the repo.
2. Run `bundle install`.
3. Run `cp .env.sample .env` to copy the sample.
4. Edit `.env` to have your correct values.
5. Setup a cron job or something to run `main.rb` on some regular interval (I run it every 5 minutes).

### Options

Run `ruby main.rb --help` for the list of arguments. They exist to disable polling for different sources in case you want to skip them. For example, if you don't care about tweets or don't want to setup a Twitter developer account you can run `ruby main.rb --no-twitter`.
