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
require 'haven-map/map'

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

		@tiles = HavenMap::Map.new
		@maps = {}
		@merged = HavenMap::Map.new
		@unmerged = []

		@zoom_level = DEFAULT_ZOOM
		@tile_size = BASE_TILE_SIZE
		@offset = Coords.new(BASE_TILE_SIZE / 2, BASE_TILE_SIZE / 2)

		read_maps

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
			map = HavenMap::Map.new basedir, i
			@maps[i] = map

			if map.offset
				map.each do |coords, tile|
					@merged[coords + map.offset] = tile
				end
			else
				@unmerged.push map
			end
		end
	end

	def map_draw widget, cairo
		@tiles.draw :target => @map,
			:cairo => cairo,
			:tile_size => @tile_size,
			:offset => @offset,
			:show_source => (@show_source and @zoom_level >= 0),
			:show_grid => @show_grid
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
			@tiles = HavenMap::Map.new
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

	def merger_start
		merger_next
		@builder.get_object('merger').show
	end

	def merger_next
		if !@unmerged.empty? then
			@merging = @unmerged.shift
			@merger_offset = HavenMap::Coords.new
			@merging_offset = HavenMap::Coords.new
		end
	end

	def merger_draw widget, cairo
		@merger_map = @builder.get_object('merger-map')
		@merged.draw :target => @merger_map,
			:cairo => cairo,
			:tile_size => BASE_TILE_SIZE,
			:offset => @merger_offset,
			:show_source => false,
			:show_grid => true,
			:background => true
		if @merging then
			@merging.draw :target => @merger_map,
				:cairo => cairo,
				:tile_size => 100,
				:offset => @merger_offset + @merging_offset * BASE_TILE_SIZE,
				:show_source => false,
				:show_grid => true
		end
	end

end # class Core

end # module HavenMap
