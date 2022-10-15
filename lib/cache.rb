# typed: strict

require "fileutils"

class Cache
	extend T::Sig

	sig {params(name: String).void}
	def initialize(name)
		@name = name
		@ids = T.let(Set.new, T::Set[String])

		path = cache_file_path
		if File.exist?(path)
			@ids.merge(File.readlines(path).map(&:strip).compact)
		end
	end

	sig {params(id: String).returns(T::Boolean)}
	def include?(id)
		@ids.include?(id)
	end

	sig {params(id: String).void}
	def write(id)
		@ids.add(id)
		FileUtils.mkdir_p(cache_directory)
		File.write(cache_file_path, @ids.join("\n"))
	end

	sig {returns(String)}
	private def cache_directory
		"cache"
	end

	sig {returns(String)}
	private def cache_file_path
		File.join(cache_directory, @name)
	end
end
