require "rubygems"
require "bundler/setup"
require "dotenv/load"
require "optparse"
require_relative "lib/log"
require_relative "lib/discord"
require_relative "lib/announcements"
require_relative "lib/news"
require_relative "lib/twitter"
require_relative "lib/youtube"

log = Log.new
discord = Discord.new(log)

sources = [
	Announcements.new(log, discord),
	News.new(log, discord),
	Twitter.new(log, discord),
	YouTube.new(log, discord),
]

OptionParser.new do |parser|
  parser.banner = "Usage: main.rb [options]"
  sources.each do |source|
  	parser.on("--no-#{source.name.downcase}", "Skip #{source.name}") do |v|
  		sources.delete(source)
  	end
  end
end.parse!

log.info("Getting Overwatch News!")
sources.each(&:execute)
