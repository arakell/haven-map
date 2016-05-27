# encoding: utf-8

require 'haven-map/coords'
require 'haven-map/tile'

module HavenMap

#class Layer < Hash
class Layer
	attr_reader :offset, :tiles, :tilemap

	#def initialize root = nil, name = nil
	def initialize args = {}
		@number = args[:number]
		@tiles = args[:tiles]
		@name = args[:name]
		recount

		# TODO size
		# TODO initialize this on map load, not app start

		#@pixbuf = Gdk::Pixbuf.new Gdk::Pixbuf::COLORSPACE_RGB, true, 8, (@bounds.width + 1) * TILE_SIZE, (@bounds.height + 1) * TILE_SIZE
		#each do
			##size = args[:target].allocation
			#each do |coords, tile|
				#tile_offset = (coords - @bounds.min) * TILE_SIZE
				##puts "draw to #{tile_offset} / #{[@bounds.width, 1].max * TILE_SIZE}×#{[@bounds.height, 1].max * TILE_SIZE}"

				#pixbuf = tile.pixbuf TILE_SIZE
				#pixbuf.copy_area 0, 0, TILE_SIZE, TILE_SIZE, @pixbuf, tile_offset.x, tile_offset.y
			#end
		#end
	end

	def retile tiles
		#puts "RETILE"
		#ap tiles
		if tiles.kind_of? DataMapper::Collection
			@tiles = @tiles.concat(tiles).current
		elsif tiles.kind_of? Array
			tiles.each do |tile|
				puts "retile: #{tile}"
				@tiles.push tile if tile
			end
		elsif tiles.kind_of? Tile
			@tiles.push tiles
		end
		@surface = nil
		recount
	end

	def recount
		@bounds = Bounds.new
		@tilemap = {}
		@tiles.each do |tile|
			@bounds.expand! tile.coords
			@tilemap[tile.coords.to_s] = tile
		end

		@offset = @bounds.min * TILE_SIZE - TILE_SIZE / 2
	end

	def surface
		return @surface if @surface

		@surface = Cairo::ImageSurface.new Cairo::FORMAT_ARGB32, (@bounds.width + 1) * TILE_SIZE, (@bounds.height + 1) * TILE_SIZE
		@context = Cairo::Context.new @surface
		@tiles.each do |tile|
			tile_offset = (tile.coords - @bounds.min) * TILE_SIZE
			@context.set_source tile.surface, tile_offset.x, tile_offset.y
			@context.paint
		end
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
			coords = Coords::new(x,y)
			self[coords] = HavenMap::Tile.new :x => x, :y => y,
				:filename => mapdir + item,
				:map => name
			@bounds.expand! coords
		end
	end

	def draw args
		# TODO reimplement zoom

		return if !surface

		cairo = args[:target]
		
		cairo.set_operator Cairo::OPERATOR_OVER
		cairo.set_source surface, args[:offset].x + @offset.x, args[:offset].y + @offset.y
		cairo.paint args[:alpha]

		if args[:desaturate]
			cairo.set_source_rgba 0, 0, 0, args[:desaturate]
			cairo.set_operator Cairo::OPERATOR_HSL_SATURATION
			cairo.mask Cairo::SurfacePattern.new cairo.target
		end

		#TODO grid?
		#TODO show_source?
		#TODO background?

		#offset = Coords.new(size.width / 2, size.height / 2)
		#each do |coords, tile|
			#tile_offset = offset + coords * tile_size + args[:offset]

			#next if tile_offset.x + tile_size < 0 or tile_offset.y + tile_size < 0
			#next if tile_offset.x > size.width or tile_offset.y > size.height

			#pixbuf = tile.pixbuf(tile_size)
			#if args[:background] then
				#pixbuf = pixbuf.saturate_and_pixelate 0.3, false
			#end

			#date, time = tile.map.split(/ /, 2)

			#if args[:show_source] then
				#cairo.set_source_rgb 1, 1, 1
				#cairo.select_font_face "Sans", Cairo::FONT_SLANT_NORMAL, Cairo::FONT_WEIGHT_NORMAL
				#cairo.set_font_size 10
				#cairo.move_to tile_offset.x, tile_offset.y + 10
				#cairo.show_text date
				#cairo.move_to tile_offset.x, tile_offset.y + 20
				#cairo.show_text time
			#end

			#if args[:show_grid] then
				#cairo.set_source_rgba 1, 0, 0, 0.5
				#cairo.move_to tile_offset.x + tile_size - 1, tile_offset.y
				#cairo.line_to tile_offset.x, tile_offset.y
				#cairo.line_to tile_offset.x, tile_offset.y + tile_size - 1
				#cairo.stroke
			#end
		#end
	end

	def merge source, offset
		source.tiles.each do |tile|
			tile.coords += offset
			tile.current = true
			tile.layer = @number
			tile.save

			oldtile = tilemap[tile.coords.to_s]
			oldtile.update current: false if oldtile
		end

		retile source.tiles
	end


	#def merge! map
		#map.each do |coords, tile|
			#self[coords + map.offset] = tile
		#end
	#end
end # class Map

end # module HavenMap
