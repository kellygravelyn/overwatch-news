require "rubygems"
require "bundler/setup"
require "dotenv/load"
require "excon"
require "json"

class Discord
	def initialize(log)
		@log = log
		@disabled = ENV["NO_DISCORD"] != nil && ENV["NO_DISCORD"] != ""
	end

	def post(data)
		loop do
			if @disabled
				@log.info("Would post JSON to Discord: #{JSON.pretty_generate(data)}")
				return true
			end

			@log.info("Posting JSON to Discord: #{JSON.pretty_generate(data)}")

			response = Excon.post(
				ENV["DISCORD_HOOK_URL"],
				body: data.to_json,
				headers: {
					"Content-Type" => "application/json"
				}
			)

			if response.headers["x-ratelimit-remaining"] == "0"
				sleep_time = response.headers["x-ratelimit-reset-after"]
				@log.warning("Discord requests exhausted. Pre-emptively sleeping #{sleep_time} second(s) to avoid 429 errors")
				sleep(sleep_time.to_f)
			end

			case response.status
			when 401
				throw StandardError.new("Discord webhook is unauthenticated")
			when 404
				throw StandardError.new("Discord webhook is not found")
			when 429
				sleep_time = response.headers["retry-after"].to_f / 1000.0
				@log.error("Discord rate limited! Sleeping for #{sleep_time} second(s) and retrying…")
				sleep(sleep_time)
				next
			when 204
				return true
			else
				@log.error("Failed to post to Discord: (#{response.status}) #{response.body}")
				return false
			end
		end
	end
end
