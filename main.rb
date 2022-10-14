require "rubygems"
require "bundler/setup"
require "dotenv/load"
require "optparse"
require_relative "lib/multi_logger"
require_relative "lib/discord"
require_relative "lib/announcements"
require_relative "lib/news"
require_relative "lib/twitter"
require_relative "lib/youtube"

stderr_log = Logger.new(STDERR)
stderr_log.level = Logger::INFO

file_log = Logger.new("log.txt", 1, (1024 ** 2) * 50)
file_log.level = Logger::DEBUG

logger = MultiLogger.new(stderr_log, file_log)

discord = Discord.new(logger)

sources = [
	Announcements.new(logger, discord),
	News.new(logger, discord),
	Twitter.new(logger, discord),
	YouTube.new(logger, discord),
]

OptionParser.new do |parser|
  parser.banner = "Usage: main.rb [options]"
  sources.each do |source|
  	parser.on("--no-#{source.name.downcase}", "Skip #{source.name}") do |v|
  		sources.delete(source)
  	end
  end
end.parse!

logger.info("Getting Overwatch News!")
sources.each(&:execute)
