# typed: strict

require_relative "cache"
require_relative "discord"

class Source
	extend T::Sig
	extend T::Helpers
	abstract!

	sig {params(log: Log, discord: Discord).void}
	def initialize(log, discord)
		@log = log
		@discord = discord
		@cache = T.let(Cache.new(name.downcase), Cache)
	end

	sig {abstract.returns(String)}
	def icon;	end

	sig {abstract.returns(T::Array[T::Hash[String, T.untyped]])}
	def fetch_items; end

	sig {params(item: T::Hash[String, T.untyped]).returns(T::Hash[String, T.untyped])}
	def format_discord_message(item)
		{ "content" => item["url"] }
	end

	sig {params(item: T::Hash[String, T.untyped]).returns(String)}
	def item_identifier(item)
		item["id"].to_s
	end

	sig {returns(String)}
	def name
		T.must(self.class.name)
	end

	sig {void}
	def execute
		@log.info("#{icon} Fetching #{name} items…")
		items = fetch_items
		item_ids = items.map { |i| item_identifier(i) }

		new_ids = item_ids.filter { |i| !@cache.include?(i) }

		if new_ids.size > 0
			new_items = items.filter { |i| new_ids.include?(item_identifier(i)) }
			new_items.reverse_each do |item|
				if @discord.post(format_discord_message(item))
					@cache.write(item_identifier(item))
				end
			end
		end
	end
end
