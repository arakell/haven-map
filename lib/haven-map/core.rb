# encoding: utf-8

# TODO
# - merge mode
# - configuration file
# - multiple map dirs
# - saving window state
# - zooming

require 'gtk3'
require 'xdg'
require 'yaml'
require 'optparse'
require 'awesome_print'

require 'haven-map/utils'
require 'haven-map/coords'
require 'haven-map/tile'

BASE_TILE_SIZE = 100
MIN_ZOOM = 0
MAX_ZOOM = 0

module HavenMap

class Core

	def initialize
		Gtk::init

		@path = '/home/qba/.local/haven/map'
		self.zoom = 0

		@tiles = {}
		@maps = {}
		@offset = Coords.new

		read_maps
		merge_maps

		@mode = :init

		@builder = Gtk::Builder.new
		uifile = HavenMap::resource 'haven-map.ui'
		@builder.add_from_file uifile

		model = @builder.get_object 'maps'
		iter = model.append
		iter[0] = 'merged'

		@maps.each do |key, val|
			iter = model.append
			iter[0] = key
		end

		@builder.connect_signals do |handler|
			method handler
		end
		@map = @builder.get_object 'map'

		@window = @builder.get_object 'main-window'
		@window.show

		Gtk.main
	end

	def read_maps
		basedir = Pathname.new(@path)
		Dir.entries(basedir).select(){|i| i[0] != '.' and Dir.exists? basedir + i }.sort.each do |i|
			map = read_map basedir + i
			@maps[i] = map
			if !@merged
				@merged = map.clone
			else
				offsetFile = basedir + i + 'offset'
				if offsetFile.exist?
					x, y = offsetFile.readlines[0].split(/,/).map{|s| s.to_i}
					map.each do |coords, tile|
						newcoords = coords + Coords.new(x, y)
						@merged[newcoords] = tile
					end
				end
			end
		end
	end

	def read_map mapdir
		# TODO offsets and multiple dirs
		tiles = {}
		Dir.entries(mapdir).each do |item|
			/^tile_(?<x>[0-9-]*)_(?<y>[0-9-]*)\.png$/ =~ item or next
			#tiles["#{x}|#{y}"] = HavenMap::Tile.new x, y, mapdir + item
			tiles[Coords::new(x,y)] = HavenMap::Tile.new x, y, mapdir + item
		end

		tiles
	end

	def merge_maps
	end

	def map_draw widget, cairo
		size = @map.allocation

		#cairo.set_source_rgb 0, 0, 0
		#cairo.arc 0, 0, 5, 0, 2*Math::PI
		#cairo.fill

		#cairo.arc size.width / 2, size.height / 2, 5, 0, 2*Math::PI
		#cairo.fill

		# TODO draw only visible tiles (is this even necessary?)
		offset = Coords.new((size.width - @tile_size) / 2, (size.height - @tile_size) / 2)
		@tiles.each do |coords, tile|
			#tile_offset = offset + tile.coords * @tile_size + @offset
			tile_offset = offset + coords * @tile_size + @offset
			cairo.set_source_pixbuf tile.pixbuf, tile_offset.x, tile_offset.y
			cairo.paint
		end

	end

	def zoom= level
		@zoomLevel = level
		@zoomLevel = MIN_ZOOM if @zoomLevel < MIN_ZOOM
		@zoomLevel = MAX_ZOOM if @zoomLevel < MAX_ZOOM
		@zoom = 2 ** @zoomLevel
		#puts "#{@zoomLevel} → #{@zoom}"
		@tile_size = BASE_TILE_SIZE * @zoom
	end

	def zoom diff
		self.zoom = @zoomLevel + diff
	end

	def quit
		Gtk.main_quit
	end

	def map_drag_start widget, event
		@drag = Coords.new event
	end

	def map_drag widget, event
		if @drag then
			diff = Coords.new(event) - @drag
			@offset += diff
			@drag.reset event
			@map.queue_draw
		end
	end

	def map_drag_stop widget, event
		@drag = nil
	end

	def map_scroll widget, event
		# TODO
		if event.direction == Gdk::EventScroll::Direction::UP then
			zoom 1
		elsif event.direction == Gdk::EventScroll::Direction::UP then
			zoom(-1)
		end
	end

	def select_map widget
		if !widget.selected
			@tiles = {}
		elsif widget.selected[0] == 'merged'
			@tiles = @merged
		else
			@tiles = @maps[widget.selected[0]]
		end
		@offset = Coords.new
		@map.queue_draw
	end

end # class Core

end # module HavenMap
