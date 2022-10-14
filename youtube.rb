require "rubygems"
require "bundler/setup"
require "dotenv/load"
require "excon"
require "nokogiri"
require_relative "cache"
require_relative "discord"

def get_video_ids
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
		Discord.post({
			"content" => "https://youtube.com/watch?v=#{id}"
		})
		sleep(1)
	end
end

cache = Cache.new("youtube")

cached_ids = cache.read

ids = get_video_ids

new_ids = ids - cached_ids

if new_ids.size > 0
	post_to_discord(new_ids)
end

cache.write(ids)
