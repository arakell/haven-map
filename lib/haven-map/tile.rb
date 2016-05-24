# encoding: utf-8

require 'haven-map/coords'
require 'haven-map/coords'
require 'data_mapper'

module HavenMap

class Tile
	include DataMapper::Resource

	property :id, String, key: true
	property :coords, Coords
	property :layer, Integer
	property :date, Date
	property :current, Boolean, default: true
	property :home, Boolean, default: false
	property :filename, String

	belongs_to :source

	attr_reader :map

	def initialize args
		self.coords = Coords.new args[:x].to_i, args[:y].to_i
		self.filename = args[:filename]
		@map = args[:map]
		@pixbuf = {}
	end

	def pixbuf size = 100
		return @pixbuf[size] if @pixbuf[size]

		@pixbuf[size] = (size == 100) ?
			Gdk::Pixbuf.new(@filename.to_s) :
			self.pixbuf.scale(size, size)
	end

	def surface
		@surface ||= Cairo::ImageSurface.from_png(@filename.to_s)
	end

end # class Tile

end # module HavenMap
