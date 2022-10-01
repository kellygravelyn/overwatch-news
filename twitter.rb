require "rubygems"
require "bundler/setup"
require "dotenv/load"
require "excon"
require "json"
require "time"
require "date"

CACHE_FILE_PATH = "twitter.json"

def get_tweet_ids
	response = Excon.get(
		"https://api.twitter.com/2/users/2420931980/tweets?exclude=replies%2Cretweets",
		headers: {
			"Authorization" => "Bearer #{ENV["TWITTER_API_BEARER_TOKEN"]}",
			"Content-Type" => "application/json"
		}
	)

	if response.status != 200
		throw StandardError.new("Failed to get tweets: (#{response.status}) #{response.body}")
	end

	JSON.parse(response.body)["data"].map {|t| t["id"]}
end

def post_to_discord(ids)
	ids.each do |id|
		data = {
			"content": "https://twitter.com/PlayOverwatch/status/#{id}"
		}

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

		sleep(1)
	end
end

cached_ids = []
if File.exists?(CACHE_FILE_PATH)
	cached_ids = JSON.parse(File.read(CACHE_FILE_PATH))
end

ids = get_tweet_ids

new_ids = ids - cached_ids

if new_ids.size > 0
	post_to_discord(new_ids)
end

File.write(CACHE_FILE_PATH, JSON.pretty_generate(ids))
