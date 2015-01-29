# encoding: utf-8

require 'haven-map/coords'

module HavenMap

class Tile
	attr_reader :map, :coords, :filename

	def initialize args
		@coords = Coords.new args[:x].to_i, args[:y].to_i
		@filename = args[:filename]
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
		return @surface if @surface
		@surface = Cairo::ImageSurface.from_png(@filename.to_s)
	end

end # class Tile

end # module HavenMap
