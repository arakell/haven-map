require 'haven-map/coords'

module HavenMap

class Tile
	attr_reader :x, :y, :coords, :filename

	def initialize x, y, filename
		@x = x.to_i
		@y = y.to_i
		@coords = Coords.new @x, @y
		@filename = filename
	end

	def pixbuf
		return @pixbuf if @pixbuf
		@pixbuf = Gdk::Pixbuf.new @filename.to_s
	end

	def surface
		return @surface if @surface
		@surface = Cairo::ImageSurface.from_png(@filename.to_s)
	end

end # class Tile

end # module HavenMap
