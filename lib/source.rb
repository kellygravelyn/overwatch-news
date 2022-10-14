require_relative "cache"
require_relative "discord"

class Source
	def initialize(logger, discord)
		@logger = logger
		@discord = discord
		@cache = Cache.new(name.downcase)
	end

	def fetch_items
		raise "method should be implemented by derived class"
	end

	def format_discord_message(item)
		{ "content" => item["url"] }
	end

	def item_identifier(item)
		item["id"]
	end

	def name
		self.class.name
	end

	def execute
		@logger.info("Fetching #{name} items…")
		items = fetch_items
		item_ids = items.map { |i| item_identifier(i) }

		new_ids = item_ids.filter { |i| !@cache.include?(i) }

		if new_ids.size > 0
			new_items = items.filter { |i| new_ids.include?(item_identifier(i)) }
			new_items.reverse_each do |item|
				@logger.info("Sending #{name} item #{item_identifier(item)} to Discord…")
				if @discord.post(logger, format_discord_message(item))
					@cache.write(item_identifier(item))
				end
			end
		end
	end
end
