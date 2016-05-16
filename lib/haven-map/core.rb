# encoding: utf-8

require 'yaml'
require 'optparse'

require 'gtk3'
require 'xdg'
require 'awesome_print'

require 'haven-map/utils'
require 'haven-map/coords'
require 'haven-map/tile'
require 'haven-map/map-handler'
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

		model = @builder.get_object 'maps'
		mergediter = model.append
		mergediter[0] = 'merged'

		@maps.each do |key, val|
			iter = model.append
			iter[0] = key
		end

		@main_map = MapHandler.new @map,
			:tile_size => BASE_TILE_SIZE,
			:zoom => { :min => MIN_ZOOM, :max => MAX_ZOOM }

		@merger_map = MapHandler.new @builder.get_object('merger-map'),
			:tile_size => BASE_TILE_SIZE / 2,
			:zoom => { :min => -3, :max => 0 },
			:base => @merged

		if @unmerged.empty? then
			@builder.get_object('merge').sensitive = false
		end

		Gtk.main
	end

	def read_maps
		basedir = Pathname.new(@path)
		Dir.entries(basedir).select(){|i| i[0] != '.' and Dir.exists? basedir + i }.sort.each do |i|
			map = HavenMap::Map.new basedir, i
			next if map.empty?

			@maps[i] = map

			if map.offset
				@merged.merge! map
			else
				@unmerged.push map
			end
		end
	end

	def quit
		Gtk.main_quit
	end

	def select_map widget
		if !widget.selected
			@tiles = HavenMap::Map.new
			@main_map.clear
		elsif widget.selected[0] == 'merged'
			@tiles = @merged
			@main_map.base = @merged
		else
			@tiles = @maps[widget.selected[0]]
			@main_map.base = @maps[widget.selected[0]]
		end
		@map.queue_draw
	end

	def zoom_in
		@main_map.zoom_in
	end

	def zoom_out
		@main_map.zoom_out
	end

	def zoom_normal
		@main_map.zoom_normal
	end


	def merger_start
		return if @unmerged.empty?

		if !@merging then
			merger_next
		end
		@builder.get_object('merger').show
	end

	def merger_next
		if @merging then
			@unmerged.push @merging
		end

		if !@unmerged.empty? then
			@merging = @unmerged.shift
			@merger_map.overlay = @merging
		else
			@builder.get_object('merge').sensitive = false
			merger_close
		end
	end

	def merger_confirm
		@merging.write_offset! @merger_map.overlay_position
		@merged.merge! @merging
		@merging = nil
		@main_map.redraw # just in case it's the merged map
		merger_next
	end

	def merger_skip
		merger_next
	end

	def merger_close
		@builder.get_object('merger').hide
		true
	end

	def merger_left
		@merger_map.overlay_move Coords.new(-1,0)
	end

	def merger_right
		@merger_map.overlay_move Coords.new(1,0)
	end

	def merger_up
		@merger_map.overlay_move Coords.new(0,-1)
	end

	def merger_down
		@merger_map.overlay_move Coords.new(0,1)
	end

	def toggle_labels
		@show_labels = !@show_labels
		@main_map.show_source = @show_labels
	end

	def toggle_grid
		@show_grid = !@show_grid
		@main_map.show_grid = @show_grid
	end

	def physical_merge target
	end
end # class Core

end # module HavenMap
