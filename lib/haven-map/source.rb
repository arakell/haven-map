# encoding: utf-8

require 'data_mapper'

module HavenMap

class Source
	include DataMapper::Resource

	property :path, String
	property :mapped, Symbol

	has n, :tiles
end

end
