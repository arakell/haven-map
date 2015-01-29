# encoding: utf-8

# TODO
# - merge mode
# - configuration file
# - multiple map dirs
# - saving window state
# - custom markers
# - tile labels (toggleable) (only for zoom >= 0)
# - configuration dialog
# - grid toggling

require 'gtk3'
require 'xdg'
require 'yaml'
require 'optparse'
require 'awesome_print'

require 'haven-map/utils'
require 'haven-map/coords'
require 'haven-map/tile'

BASE_TILE_SIZE = 100
DEFAULT_ZOOM = 0
MIN_ZOOM = -4
MAX_ZOOM = 2

module HavenMap

class Core

	def initialize config
		#options = {
			#:config    => XDG['CONFIG_HOME'].to_s + "/#{APPNAME}/rc.yaml",
			#:db        => XDG['DATA_HOME'].to_s + "/#{APPNAME}/lite.sqlite3",
			#:debug     => false,
			#:mode      => 'simple',
			#:show_icon => true
		#}
		#cli = {}
		#OptionParser.new do |opts|
		#end.parse!

		#tmp = options.merge cli

		#if File.exists? tmp[:config]
			#yaml = YAML::load_file(tmp[:config]).symbolize_keys!
			#options.merge! yaml
		#end
		#options.merge! cli




		@path = '/home/qba/.local/haven/map'

		@tiles = {}
		@maps = {}

		@zoom_level = DEFAULT_ZOOM
		@tile_size = BASE_TILE_SIZE
		@offset = Coords.new(BASE_TILE_SIZE / 2, BASE_TILE_SIZE / 2)

		read_maps
		merge_maps

		@mode = :normal



		Gtk::init

		@builder = Gtk::Builder.new
		uifile = HavenMap::resource 'haven-map.ui'
		@builder.add_from_file uifile

		@builder.connect_signals do |handler|
			method handler
		end
		@map = @builder.get_object 'map'

		@window = @builder.get_object 'main-window'
		@window.show

		#maplist = @builder.get_object('maplist')
		#maplist.set_cursor maplist.get_path(0,0), nil, false

		model = @builder.get_object 'maps'
		mergediter = model.append
		mergediter[0] = 'merged'

		@maps.each do |key, val|
			iter = model.append
			iter[0] = key
		end

		Gtk.main
	end

	def read_maps
		basedir = Pathname.new(@path)
		Dir.entries(basedir).select(){|i| i[0] != '.' and Dir.exists? basedir + i }.sort.each do |i|
			map = read_map basedir, i
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

	def read_map root, map
		mapdir = root + map
		# TODO offsets and multiple dirs
		tiles = {}
		Dir.entries(mapdir).each do |item|
			/^tile_(?<x>[0-9-]*)_(?<y>[0-9-]*)\.png$/ =~ item or next
			#tiles["#{x}|#{y}"] = HavenMap::Tile.new x, y, mapdir + item
			tiles[Coords::new(x,y)] = HavenMap::Tile.new :x => x, :y => y,
				:filename => mapdir + item,
				:map => map
		end

		tiles
	end

	def merge_maps
		basedir = Pathname.new(@path)
		
	end

	def map_draw widget, cairo
		size = @map.allocation

		# TODO draw only visible tiles (is this even necessary?)
		offset = Coords.new(size.width / 2, size.height / 2)
		@tiles.each do |coords, tile|
			#tile_offset = offset + tile.coords * @tile_size + @offset
			tile_offset = offset + coords * @tile_size + @offset

			next if tile_offset.x + @tile_size < 0 or tile_offset.y + @tile_size < 0
			next if tile_offset.x > size.width or tile_offset.y > size.height

			cairo.set_source_pixbuf tile.pixbuf(@tile_size), tile_offset.x, tile_offset.y
			cairo.paint

			date, time = tile.map.split(/ /, 2)

			if @show_source and @zoom_level >= 0 then
				cairo.set_source_rgb 1, 1, 1
				cairo.select_font_face "Sans", Cairo::FONT_SLANT_NORMAL, Cairo::FONT_WEIGHT_NORMAL
				cairo.set_font_size 10
				cairo.move_to tile_offset.x, tile_offset.y + 10
				cairo.show_text date
				cairo.move_to tile_offset.x, tile_offset.y + 20
				cairo.show_text time
			end

			if @show_grid then
				cairo.set_source_rgba 1, 0, 0, 0.5
				cairo.move_to tile_offset.x + @tile_size - 1, tile_offset.y
				cairo.line_to tile_offset.x, tile_offset.y
				cairo.line_to tile_offset.x, tile_offset.y + @tile_size - 1
				cairo.stroke
			end
		end

	end

	def zoom level, center = Coords.new(0,0)
		level = MIN_ZOOM if level < MIN_ZOOM
		level = MAX_ZOOM if level > MAX_ZOOM

		return if level == @zoom_level

		@zoom_level = level
		modifier = 2 ** @zoom_level
		#@tile_size = BASE_TILE_SIZE * zoom

		#tilepos = coords_to_tile @offset
		ref = @offset - center
		tilex = ref.x.to_f / @tile_size
		tiley = ref.y.to_f / @tile_size
		#puts "#{@offset} → #{tilex}×#{tiley}"

		@tile_size = (BASE_TILE_SIZE * modifier).to_i
		@offset = Coords.new(tilex * @tile_size, tiley * @tile_size) + center
		#puts "zoom: #{@zoom_level} → #{modifier} → #{@tile_size}"

		@map.queue_draw
	end

	def zoom_in
		zoom @zoom_level + 1
	end

	def zoom_out
		zoom @zoom_level - 1
	end

	def zoom_normal
		zoom 0
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
		size = @map.allocation
		center = Coords.new(event.x - size.width / 2, event.y - size.height / 2)
		if event.direction == Gdk::EventScroll::Direction::UP then
			zoom @zoom_level + 1, center
		elsif event.direction == Gdk::EventScroll::Direction::DOWN then
			zoom @zoom_level - 1, center
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
		@offset = Coords.new(@tile_size / 2, @tile_size / 2)
		@map.queue_draw
	end

	def coords_to_tile coords
		return coords / @tile_size
	end

	def tile_to_coords
	end

end # class Core

end # module HavenMap
