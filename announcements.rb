require "rubygems"
require "bundler/setup"
require "dotenv/load"
require "excon"
require "json"

CACHE_FILE_PATH = "announcements.json"

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

		if ENV["NO_DISCORD"] != nil && ENV["NO_DISCORD"] != ""
			puts "WOULD POST TO DISCORD:"
			puts JSON.pretty_generate(data)
			next
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

latest = []
if File.exists?(CACHE_FILE_PATH)
	latest = JSON.parse(File.read(CACHE_FILE_PATH))
end

urls = get_post_urls

new_urls = urls - latest

if new_urls.size > 0
	post_to_discord(new_urls)
end

File.write(CACHE_FILE_PATH, JSON.pretty_generate(urls))
