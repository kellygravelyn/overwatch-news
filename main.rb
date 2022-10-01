require "rubygems"
require "bundler/setup"
require "dotenv/load"
require "excon"
require "nokogiri"
require "json"
require "time"
require "date"

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
		"embeds" => items.map do |item|
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

	response = Excon.post(
		ENV["DISCORD_HOOK_URL"],
		body: data.to_json,
		headers: {
			"Content-Type" => "application/json"
		}
	)
end

latest = []
if File.exists?("latest.json")
	latest = JSON.parse(File.read("latest.json"))
end

items = get_page(1)

new_items = items - latest

if new_items.size > 0
	post_to_discord(new_items)
end

File.write("latest.json", JSON.pretty_generate(items))
