require "excon"
require "nokogiri"
require "json"
require "time"
require_relative "source"

class News < Source
	def icon
		"📰"
	end

	def fetch_items
		response = Excon.get("https://overwatch.blizzard.com/en-us/news/")
		html_content = Nokogiri::HTML(response.body)

		html_content.css("blz-card").map do |card|
			title = card.css("[slot=\"heading\"]").inner_text
			url = card.attribute("href").value + "/"
			image = "https:" + card.css("[slot=\"image\"]").attribute("src").value
			timestamp = Time.parse(card.attribute("date")).iso8601

			{
				"id" => url.split("/")[-1],
				"title" => title,
				"url" => url,
				"image" => image,
				"timestamp" => timestamp,
				"description" => fetch_description(url),
			}
		end
	end

	def fetch_description(url)
		response = Excon.get(url)
		html_content = Nokogiri::HTML(response.body)
		html_content.css("meta#description").attribute("content").value.strip
	end

	def format_discord_message(item)
		{
			"embeds" => [
				"title" => item["title"],
				"color" => 15823666,
				"description" => item["description"],
				"url" => item["url"],
				"image" => {"url" => item["image"]},
				"timestamp" => item["timestamp"],
			],
		}
	end
end
