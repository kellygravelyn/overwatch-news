require "fileutils"

class Cache
	def initialize(name)
		@name = name
		@ids = Set.new

		path = cache_file_path
		if File.exists?(path)
			@ids = Set.new(File.readlines(path).map(&:strip))
		end
	end

	def include?(id)
		@ids.include?(id.to_s)
	end

	def write(id)
		@ids << id
		FileUtils.mkdir_p(cache_directory)
		File.write(cache_file_path, @ids.join("\n"))
	end

	private def cache_directory
		"cache"
	end

	private def cache_file_path
		File.join(cache_directory, @name)
	end
end
