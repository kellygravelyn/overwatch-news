require "rubygems"
require "bundler/setup"
require "dotenv/load"
require "excon"
require "json"

class Discord
	def initialize
	end

	def post(data)
		loop do
			puts "Posting JSON to Discord: #{JSON.pretty_generate(data)}"

			if ENV["NO_DISCORD"] != nil && ENV["NO_DISCORD"] != ""
				return true
			end

			response = Excon.post(
				ENV["DISCORD_HOOK_URL"],
				body: data.to_json,
				headers: {
					"Content-Type" => "application/json"
				}
			)

			if response.headers["x-ratelimit-remaining"] == "0"
				sleep_time = response.headers["x-ratelimit-reset-after"]
				puts "Discord requests exhausted. Pre-emptively sleeping #{sleep_time} second(s) to avoid 429 errors"
				sleep(sleep_time.to_f)
			end

			case response.status
			when 401
				throw StandardError.new("Discord webhook is unauthenticated")
			when 404
				throw StandardError.new("Discord webhook is not found")
			when 429
				sleep_time = response.headers["retry-after"].to_f / 1000.0
				puts "Discord rate limited! Sleeping for #{sleep_time} second(s) and retrying…"
				sleep(sleep_time)
				next
			when 204
				return true
			else
				puts "Failed to post to Discord: (#{response.status}) #{response.body}"
				return false
			end
		end
	end
end
