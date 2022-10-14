require "rubygems"
require "bundler/setup"
require "dotenv/load"
require "excon"
require "json"
require_relative "cache"
require_relative "discord"

def get_post_urls
	response = Excon.get("https://us.forums.blizzard.com/en/overwatch/c/announcements/5/l/latest.json?ascending=false")
	json = JSON.parse(response.body)

	json.dig("topic_list", "topics").map do |t|
		"https://us.forums.blizzard.com/en/overwatch/t/#{t["id"]}"
	end
end

def post_to_discord(urls)
	urls.reverse_each do |url|
		data = {
			"content" => url,
		}

		Discord.post(data)
	end
end

cache = Cache.new("announcements")

latest = cache.read

urls = get_post_urls

new_urls = urls - latest

if new_urls.size > 0
	post_to_discord(new_urls)
end

cache.write(urls)
