require "rubygems"
require "bundler/setup"
require "dotenv/load"
require "excon"
require "nokogiri"
require "json"
require "time"
require "date"

CACHE_FILE_PATH = "news.json"

def get_page(page)
	response = Excon.get("https://playoverwatch.com/en-us/news/next-posts/?page=#{page}")
	json = JSON.parse(response.body)
	html_content = Nokogiri::HTML(json["content"])

	items = html_content.css("li.NewsItem").map do |item|
		title = item.css(".NewsItem-title").inner_text
		url = "https://playoverwatch.com" + item.css(".NewsItem-title").attribute("href").value
		description = item.css(".NewsItem-summary").inner_text
		image = item.css(".Card-thumbnail").attribute("style").value
		timestamp = item.css(".NewsItem-subtitle").inner_text

		{
			"title" => title,
			"description" => description,
			"url" => url,
			"image" => "https:" + image[22...-1],
			"timestamp" => Time.parse(timestamp).iso8601
		}
	end

	items
end

def post_to_discord(items)
	data = {
		"embeds" => items.reverse.map do |item|
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

latest = []
if File.exists?(CACHE_FILE_PATH)
	latest = JSON.parse(File.read(CACHE_FILE_PATH))
end

items = get_page(1)

new_items = items - latest

if new_items.size > 0
	post_to_discord(new_items)
end

File.write(CACHE_FILE_PATH, JSON.pretty_generate(items))
