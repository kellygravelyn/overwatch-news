class Log
	def initialize
		log_formatter = proc do |severity, datetime, progname, msg|
			date_format = datetime.strftime("%F %r")
			"#{date_format}\t#{severity}\t#{msg}\n"
		end

		@stderr_log = Logger.new(STDERR, formatter: log_formatter)
		@file_log = Logger.new("log.txt", 1, formatter: log_formatter)
	end

	%w(log debug info warn error fatal unknown).each do |m|
		define_method(m) do |*args|
			@stderr_log.send(m, *args)
			@file_log.send(m, *args)
		end
	end
end
