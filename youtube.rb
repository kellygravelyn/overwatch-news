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

		id = entry.css("yt|videoId").inner_text
		timestamp = entry.css("published").inner_text
		description = entry.css("media|description").inner_text
		image = entry.css("media|thumbnail").attribute("url").value

		# Helpfully Overwatch uses hyphens and underscores to separate the actual
		# description from a bunch of link spam so we can start there.
		end_description = description.index("\n-\n") || description.index("\n_\n")
		description = description[0...end_description].strip

		# We can also look for a line of hash tags and strip that off.
		description = description.lines.select do |l|
			next true if l == "\n"
			!l.split(" ").all? { |w| w[0] == "#" }
		end.join().strip

		{
			"title" => title,
			"description" => description,
			"url" => "https://www.youtube.com/watch?v=#{id}",
			"image" => image,
			"timestamp" => Time.parse(timestamp).iso8601
		}
	end.compact
end

def post_to_discord(items)
	items.each_slice(10).reverse_each do |slice|
		data = {
			"embeds" => slice.reverse.map do |item|
				{
					"title" => item["title"],
					"color" => 15823666,
					"description" => item["description"],
					"url" => item["url"],
					"image" => {"url" => item["image"]},
					"timestamp" => item["timestamp"]
				}
			end
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

items = get_videos

new_items = items - latest

if new_items.size > 0
	post_to_discord(new_items)
end

File.write(CACHE_FILE_PATH, JSON.pretty_generate(items))
