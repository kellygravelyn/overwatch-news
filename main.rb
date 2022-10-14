require "rubygems"
require "bundler/setup"
require "dotenv/load"
require "optparse"
require_relative "lib/discord"
require_relative "lib/announcements"
require_relative "lib/news"
require_relative "lib/twitter"
require_relative "lib/youtube"

sources = [
	Announcements.new,
	News.new,
	Twitter.new,
	YouTube.new,
]

OptionParser.new do |parser|
  parser.banner = "Usage: main.rb [options]"
  sources.each do |source|
  	parser.on("--no-#{source.name.downcase}", "Skip #{source.name}") do |v|
  		sources.delete(source)
  	end
  end
end.parse!

discord = Discord.new
sources.each do |s|
	s.execute(discord)
end
