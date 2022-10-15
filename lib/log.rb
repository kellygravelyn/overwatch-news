# typed: strict

class Log
	extend T::Sig

	sig {void}
	def initialize
		log_formatter = proc do |severity, datetime, progname, msg|
			date_format = datetime.strftime("%F %r")
			"#{date_format}\t#{severity}\t#{msg}\n"
		end

		@stderr_log = T.let(Logger.new(STDERR, formatter: log_formatter), Logger)
		@file_log = T.let(Logger.new("log.txt", 1, formatter: log_formatter), Logger)
	end

	sig {params(msg: String).void}
	def info(msg)
		@stderr_log.info(msg)
		@file_log.info(msg)
	end

	sig {params(msg: String).void}
	def warn(msg)
		@stderr_log.warn(msg)
		@file_log.warn(msg)
	end

	sig {params(msg: String).void}
	def error(msg)
		@stderr_log.error(msg)
		@file_log.error(msg)
	end
end
