# encoding: utf-8

require 'haven-map/coords'
require 'haven-map/coords'
require 'data_mapper'

module HavenMap

class Tile
	include DataMapper::Resource

	property :id, Serial, key: true
	property :coords, Coords
	#property :coords, HavenMap::Coords
	property :layer, Integer, default: 0
	property :date, DateTime
	property :current, Boolean, default: true
	property :filename, String, length: 256

	belongs_to :source, required: false

	def initialize args
		super args

		if args[:filename]
			/^tile_(?<x>[0-9-]*)_(?<y>[0-9-]*)\.png$/ =~ args[:filename].basename
			self.coords = Coords.new x, y
		end
	end

	def pixbuf
		@pixbuf ||= Gdk::Pixbuf.new @filename.to_s
		#@pixbuf[size] = (size == 100) ?
			#Gdk::Pixbuf.new(@filename.to_s) :return 
			#self.pixbuf.scale(size, size)
	end

	def surface
		@surface ||= Cairo::ImageSurface.from_png @filename.to_s
	end

	def self.current
		all current: true
	end

end # class Tile

end # module HavenMap
