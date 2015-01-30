# encoding: utf-8

require 'haven-map/coords'
require 'haven-map/tile'

module HavenMap

class Map < Hash
	attr_reader :offset

	def initialize root = nil, name = nil
		read root, name if root and name
	end

	def write_offset! offset
		@offset = offset
		File.open(@offset_file, 'w') {|f| f.write(@offset) }
	end

	def read root, name
		mapdir = root + name
		@offset_file = mapdir + 'offset'
		if @offset_file.exist?
			ox, oy = @offset_file.readlines[0].split(/,/).map{|s| s.to_i}
			@offset = Coords.new(ox, oy)
		end

		Dir.entries(mapdir).each do |item|
			/^tile_(?<x>[0-9-]*)_(?<y>[0-9-]*)\.png$/ =~ item or next
			self[Coords::new(x,y)] = HavenMap::Tile.new :x => x, :y => y,
				:filename => mapdir + item,
				:map => name
		end
	end

	def draw args
		size = args[:target].allocation
		cairo = args[:target].window.create_cairo_context
		tile_size = args[:tile_size]

		offset = Coords.new(size.width / 2, size.height / 2)
		each do |coords, tile|
			tile_offset = offset + coords * tile_size + args[:offset]

			next if tile_offset.x + tile_size < 0 or tile_offset.y + tile_size < 0
			next if tile_offset.x > size.width or tile_offset.y > size.height

			pixbuf = tile.pixbuf(tile_size)
			if args[:background] then
				pixbuf = pixbuf.saturate_and_pixelate 0.3, false
			end

			cairo.set_source_pixbuf pixbuf, tile_offset.x, tile_offset.y
			cairo.paint args[:alpha]

			date, time = tile.map.split(/ /, 2)

			if args[:show_source] then
				cairo.set_source_rgb 1, 1, 1
				cairo.select_font_face "Sans", Cairo::FONT_SLANT_NORMAL, Cairo::FONT_WEIGHT_NORMAL
				cairo.set_font_size 10
				cairo.move_to tile_offset.x, tile_offset.y + 10
				cairo.show_text date
				cairo.move_to tile_offset.x, tile_offset.y + 20
				cairo.show_text time
			end

			if args[:show_grid] then
				cairo.set_source_rgba 1, 0, 0, 0.5
				cairo.move_to tile_offset.x + tile_size - 1, tile_offset.y
				cairo.line_to tile_offset.x, tile_offset.y
				cairo.line_to tile_offset.x, tile_offset.y + tile_size - 1
				cairo.stroke
			end
		end
	end


	def merge! map
		map.each do |coords, tile|
			self[coords + map.offset] = tile
		end
	end
end # class Map

end # module HavenMap
