require "rubygems"
require "bundler/setup"
require "dotenv/load"
require "excon"
require "json"

module Discord
	def self.post(data)
		if ENV["NO_DISCORD"] != nil && ENV["NO_DISCORD"] != ""
			puts "WOULD POST TO DISCORD:"
			puts JSON.pretty_generate(data)
			return
		end

		response = Excon.post(
			ENV["DISCORD_HOOK_URL"],
			body: data.to_json,
			headers: {
				"Content-Type" => "application/json"
			}
		)

		if response.status != 204
			puts "Failed to post to Discord: (#{response.status}) #{response.body}"
		end
	end
end
