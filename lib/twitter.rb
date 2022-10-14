require "excon"
require "nokogiri"
require "json"
require "time"
require_relative "source"

class Twitter < Source
	def fetch_items
		response = Excon.get(
			"https://api.twitter.com/2/users/2420931980/tweets?exclude=replies,retweets",
			headers: {
				"Authorization" => "Bearer #{ENV["TWITTER_API_BEARER_TOKEN"]}",
				"Content-Type" => "application/json"
			}
		)

		if response.status != 200
			throw StandardError.new("Failed to get tweets: (#{response.status}) #{response.body}")
		end

		json = JSON.parse(response.body)

		json["data"].map do |t|
			{
				"id" => t["id"],
				"url" => "https://twitter.com/PlayOverwatch/status/#{t["id"]}",
			}
		end
	end
end
