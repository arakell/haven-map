# encoding: utf-8

require 'data_mapper'

module HavenMap

class Source
	include DataMapper::Resource

	property :path, String, key: true
	property :status, Enum[:new, :unmerged, :merged, :discarded], default: :new
	property :date, DateTime
	property :type, Enum[:surface, :cave]

	has n, :tiles

	def self.sorted
		all order: [ :date.asc ]
	end

	def self.merged
		all status: :merged
	end

	def self.discarded
		all status: :discarded
	end

	def self.unmerged
		all status: [:unmerged, :new]
	end



	def read_tiles basedir
		return if status != :new

		Dir.entries(basedir + path).
			select{ |f| f[0] != '.' }.
			#map { |f| Tile.new filename: basedir + path + f, date: date, source: self }.
			map { |f| Tile.new filename: basedir + path + f, date: date }.
			each { |t| self.tiles.push t }

		#update status: :unmerged
	end

	def to_s
		path
	end

end # class Source

end # module HavenMap
