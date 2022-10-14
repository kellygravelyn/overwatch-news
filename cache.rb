require "fileutils"

class Cache
	def initialize(name)
		@name = name
	end

	def read_ids
		path = cache_file_path

		if File.exists?(path)
			File.readlines(path).map(&:strip)
		else
			[]
		end
	end

	def write_ids(ids)
		FileUtils.mkdir_p(cache_directory)
		File.write(cache_file_path, ids.join("\n"))
	end

	def cache_directory
		"cache"
	end

	def cache_file_path
		File.join(cache_directory, @name)
	end
end
