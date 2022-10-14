require "fileutils"

class Cache
	def initialize(name)
		@name = name
	end

	def read
		path = cache_file_path

		if File.exists?(path)
			File.readlines(path).map(&:strip)
		else
			[]
		end
	end

	def write(values)
		FileUtils.mkdir_p(cache_directory)
		File.write(cache_file_path, values.join("\n"))
	end

	def cache_directory
		"cache"
	end

	def cache_file_path
		File.join(cache_directory, @name)
	end
end
