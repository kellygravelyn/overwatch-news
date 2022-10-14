require "rubygems"
require "bundler/setup"
require "dotenv/load"
require "excon"
require "json"
require "time"
require "date"
require_relative "cache"
require_relative "discord"

def get_tweets
	response = Excon.get(
		"https://api.twitter.com/2/users/2420931980/tweets?exclude=replies,retweets&tweet.fields=referenced_tweets&expansions=referenced_tweets.id,referenced_tweets.id.author_id&user.fields=name,id,url,username,profile_image_url",
		headers: {
			"Authorization" => "Bearer #{ENV["TWITTER_API_BEARER_TOKEN"]}",
			"Content-Type" => "application/json"
		}
	)

	if response.status != 200
		throw StandardError.new("Failed to get tweets: (#{response.status}) #{response.body}")
	end

	json = JSON.parse(response.body)

	tweets_by_id = json["includes"]["tweets"].map do |t|
		[t["id"], t]
	end.to_h

	users_by_id = json["includes"]["users"].map do |u|
		[u["id"], u]
	end.to_h

	json["data"].map do |t|
		{
			"id" => t["id"],
			"url" => "https://twitter.com/PlayOverwatch/status/#{t["id"]}",
			"referenced_tweets" => (t["referenced_tweets"] || []).map do |r|
				referenced_tweet = tweets_by_id[r["id"]]
				user = users_by_id[referenced_tweet["author_id"]]

				{
					"url" => "https://twitter.com/#{user["username"]}/status/#{r["id"]}"
				}
			end
		}
	end
end

def post_to_discord(tweets)
	tweets.reverse_each do |t|
		Discord.post({ "content" => t["url"] })
		sleep(1)

		t["referenced_tweets"].each do |r|
			Discord.post({ "content" => "↪ #{r["url"]}" })
		end
	end
end

cache = Cache.new("twitter")

cached_ids = cache.read

tweets = get_tweets
tweet_ids = tweets.map {|t| t["id"]}

new_ids = tweet_ids - cached_ids

if new_ids.size > 0
	tweets_to_post = tweets.filter {|t| new_ids.include?(t["id"])}
	post_to_discord(tweets_to_post)
end

cache.write(tweet_ids)
