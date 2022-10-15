# typed: strict

require "excon"
require "nokogiri"
require "json"
require "time"
require_relative "source"

class YouTube < Source
	extend T::Sig

	sig {override.returns(String)}
	def icon
		"🎥"
	end

	sig {override.returns(T::Array[T::Hash[String, T.untyped]])}
	def fetch_items
		response = Excon.get(
			"https://www.youtube.com/feeds/videos.xml?channel_id=UClOf1XXinvZsy4wKPAkro2A",
		)

		if response.status != 200
			throw StandardError.new("Failed to get YouTube RSS: (#{response.status}) #{response.body}")
		end

		xml = Nokogiri::XML.parse(response.body)

		xml.css("entry").map do |entry|
			id = entry.css("yt|videoId").inner_text
			title = entry.css("title").inner_text

			# Skip OWL costreams
			next nil if title.downcase.include?("costream")

			{
				"id" => id,
				"url" => "https://youtube.com/watch?v=#{id}"
			}
		end.compact
	end
end
