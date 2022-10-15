# typed: strict

require "excon"
require "json"
require_relative "source"

class Announcements < Source
	extend T::Sig

	sig {override.returns(String)}
	def icon
		"📢"
	end

	sig {override.returns(T::Array[T::Hash[String, T.untyped]])}
	def fetch_items
		response = Excon.get("https://us.forums.blizzard.com/en/overwatch/c/announcements/5/l/latest.json?ascending=false")
		json = JSON.parse(response.body)

		json.dig("topic_list", "topics").map do |t|
			{
				"id" => t["id"],
				"url" => "https://us.forums.blizzard.com/en/overwatch/t/#{t["id"]}",
			}
		end
	end
end
