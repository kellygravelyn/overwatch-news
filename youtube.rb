require "rubygems"
require "bundler/setup"
require "dotenv/load"
require "excon"
require "nokogiri"
require "json"
require "time"
require "date"

CACHE_FILE_PATH = "youtube.json"

def get_videos
	response = Excon.get(
		"https://www.youtube.com/feeds/videos.xml?channel_id=UClOf1XXinvZsy4wKPAkro2A",
	)

	if response.status != 200
		throw StandardError.new("Failed to get YouTube RSS: (#{response.status}) #{response.body}")
	end

	xml = Nokogiri::XML.parse(response.body)

	xml.css("entry").map do |entry|
		title = entry.css("title").inner_text

		# Skip OWL costreams
		next nil if title.downcase.include?("costream")

		entry.css("yt|videoId").inner_text
	end.compact
end

def post_to_discord(ids)
	ids.reverse_each do |id|
		data = {
			"content": "https://youtube.com/watch?v=#{id}"
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

		sleep(1)
	end
end

latest = []
if File.exists?(CACHE_FILE_PATH)
	latest = JSON.parse(File.read(CACHE_FILE_PATH))
end

items = get_videos

new_items = items - latest

if new_items.size > 0
	post_to_discord(new_items)
end

File.write(CACHE_FILE_PATH, JSON.pretty_generate(items))
