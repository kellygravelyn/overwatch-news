require "rubygems"
require "bundler/setup"
require "dotenv/load"
require "excon"
require "nokogiri"
require "json"
require "time"
require "date"
require_relative "cache"
require_relative "discord"

def get_description(url)
	response = Excon.get(url)
	html_content = Nokogiri::HTML(response.body)
	html_content.css("meta#description").attribute("content").value.strip
end

def get_latest_articles
	response = Excon.get("https://overwatch.blizzard.com/en-us/news/")
	html_content = Nokogiri::HTML(response.body)

	cards = html_content.css("blz-card").map do |card|
		title = card.css("[slot=\"heading\"]").inner_text
		url = card.attribute("href").value + "/"
		image = "https:" + card.css("[slot=\"image\"]").attribute("src").value
		timestamp = Time.parse(card.attribute("date")).iso8601

		{
			"id" => url.split("/")[-1],
			"title" => title,
			"url" => url,
			"image" => image,
			"timestamp" => timestamp
		}
	end

	cards
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

	Discord.post(data)
end

cache = Cache.new("news")

posted_ids = cache.read

articles = get_latest_articles
article_ids = articles.map { |a| a["id"] }

new_article_ids = article_ids - posted_ids

if new_article_ids.size > 0
	new_articles = articles.filter { |a| new_article_ids.include?(a["id"]) }

	# Since getting a description is an extra HTTP call we only
	# do it for new articles.
	new_articles.each do |a|
		a["description"] = get_description(a["url"])
	end

	post_to_discord(new_articles)
end

posted_ids += new_article_ids

cache.write(posted_ids)
