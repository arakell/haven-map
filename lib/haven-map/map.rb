require 'haven-map/layer'
require 'haven-map/coords'

module HavenMap

class Map
	attr_writer :widget, :source_toolbar
	attr_reader :overlay_position, :layers, :layer

	def initialize opts = {}
		# modes
		#   :full    - draw a compound map with higher layers underneath
		#   :layer   - draw a single layer
		#   :overlay - draw a merging overlay
		#   :source  - draw from a single source
		#   :select  - select a single tile
		@basemode = :full
		@mode = :full

		# select modes
		#   :source - choose source to analyze
		#   :home - choose home tile
		@select = :nil

		@widget = opts[:widget]
		@tiles = opts[:tiles]
		@overlay = nil
		@source = nil

		#displayed layer
		@layer = 0
		@sublayers = true

		@offset = Coords.new
		@overlay_offset = Coords.new

		@zoom_level = opts[:zoom] || 0

		#@tile_size = @base_tile_size = args[:tile_size]

		build_layers
	end

	def build_layers
		@layers = @tiles.to_a.each_with_index.map do |tiles, index|
			HavenMap::Layer.new tiles: tiles, number: index
		end
	end


	def merge type, layer, &block
		@layer = 0 if type == :surface and @layer != 0
		@layer = 1 if type == :cave and @layer == 0
		layer_update

		zoom_normal

		@overlay_cb = block
		@overlay_offset = Coords.new
		@overlay = layer
		@mode = :overlay

		redraw
	end

	def unmerge
		@mode = @basemode
		@overlay_cb = nil
		@overlay = nil
	end



	def button_press widget, event
		if @mode == :select
			if event.button == 1
				puts "selected #{@select_coords}"
				case @select
					when :source
						read_source
				end
			elsif event.button == 3
				@mode = @basemode
				redraw
			end
		elsif event.button == 1 then
			@drag = Coords.new event
			@dragmode = :offset
		elsif event.button == 3 and @overlay then
			@drag = Coords.new event
			@dragmode = :overlay
		else
			@dragmode = nil
		end
	end

	def button_release widget, event
		if @drag and @dragmode == :overlay then
			@overlay_position = @overlay_offset.rdiv TILE_SIZE
			@overlay_offset = @overlay_position * TILE_SIZE
			@overlay_cb.call @overlay_position if @overlay_cb
			redraw
		end
		@drag = nil
	end

	def layer_change from, to
		return if to.value == @layer
		@layer = to.value
		redraw
	end

	def layer_buttons= buttons
		@layer_buttons = buttons
		layer_update
	end

	def layer_update
		@layer_buttons[@layer].active = true
	end

	def scroll widget, event
		# TODO change layer with ctrl
		# TODO feed that back to sidebar
		size = @widget.allocation
		center = Coords.new(event.x - size.width / 2, event.y - size.height / 2)
		if event.direction == Gdk::ScrollDirection::UP then
			zoom @zoom_level + 1, center
		elsif event.direction == Gdk::ScrollDirection::DOWN then
			zoom @zoom_level - 1, center
		end
	end

	def motion widget, event
		if @mode == :select
			#puts "move #{Coords.new(event)}"
			size = @widget.allocation

			offset = Coords.new(size.width / 2, size.height / 2) * -1
			offset += Coords.new(event) + Coords.new(TILE_SIZE / 2, TILE_SIZE / 2)
			offset -= @offset
			offset /= TILE_SIZE

			@select_coords = offset
			redraw
		elsif @drag then
			diff = Coords.new(event) - @drag
			if @dragmode == :offset then
				@offset += diff
			elsif @dragmode == :overlay then
				@overlay_offset += diff
			end
			@drag.reset event
			redraw
		end
	end

	def motion_out widget, event
		if @mode == :select
			@select_coords = nil
			redraw
		end
	end

	def redraw
		@widget.queue_draw if @widget
	end

	def zoom level, center = Coords.new
		return if @overlay
		#return if !@options[:zoom]
		return

		level = @options[:zoom][:min] if level < @options[:zoom][:min]
		level = @options[:zoom][:max] if level > @options[:zoom][:max]

		return if level == @zoom_level

		@zoom_level = level
		modifier = 2 ** @zoom_level

		ref = @offset - center
		tilex = ref.x.to_f / @tile_size
		tiley = ref.y.to_f / @tile_size

		@tile_size = (@base_tile_size * modifier).to_i
		@offset = Coords.new(tilex * @tile_size, tiley * @tile_size) + center
		@overlay_offset = @overlay_position * @tile_size

		redraw
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

	def key_press widget, event
		puts "key press: #{event.keyval} | #{event.string}"
		case event.string
			when '`' then
				@layer = 0
				layer_update
				redraw
			when '0'..'5' then
				#puts "switch layer to: #{event.string.to_i}"
				@layer = event.string.to_i
				layer_update
				redraw
		end
		#ap event.methods
		#ap event
	end

	def draw
		size = @widget.allocation
		cairo = @widget.window.create_cairo_context

		center = Coords.new(size.width / 2, size.height / 2)

		cairo.set_source_rgba 1, 0, 0, 0.5

		cairo.move_to center.x + @offset.x - 20, center.y + @offset.y - 20
		cairo.line_to center.x + @offset.x + 20, center.y + @offset.y + 20

		cairo.move_to center.x + @offset.x - 20, center.y + @offset.y + 20
		cairo.line_to center.x + @offset.x + 20, center.y + @offset.y - 20

		cairo.stroke

		case @mode
			when :overlay
				if @layer > 0
					@layers[@layer - 1].draw :target => cairo,
						offset: @offset + center,
						alpha: 0.2,
						desaturate: 0.8
				end
				@layers[@layer].draw :target => cairo,
					offset: @offset + center,
					desaturate: 0.8
			when :full
				(0..@layer-1).each do |layer|
					@layers[layer].draw :target => cairo,
						offset: @offset + center,
						alpha: 0.5
				end

				@layers[@layer].draw :target => cairo,
					offset: @offset + center,
					alpha: @layer == 0 ? 1 : 0.8
				#@layers[0].draw :target => cairo,
					#offset: @offset + center

				#(1..@layer).each do |layer|
					#@layers[layer].draw :target => cairo,
						#offset: @offset + center,
						#alpha: 0.8
			when :layer
				@layers[@layer].draw :target => cairo,
					offset: @offset + center
			when :source
				@source_layer.draw :target => cairo,
					offset: @offset + center
			when :select
				@layers[@layer].draw :target => cairo,
					offset: @offset + center

				if @select_coords
					coords = @offset + center +
						@select_coords * TILE_SIZE -
						Coords.new(TILE_SIZE / 2, TILE_SIZE / 2)

					cairo.set_source_rgba 1, 0, 0, 0.5
					cairo.rectangle coords.x, coords.y, TILE_SIZE, TILE_SIZE
					cairo.fill
				end
		end

		#@base.draw :target => @widget,
			#:tile_size => @tile_size,
			#:offset => @offset,
			#:show_source => (@show_source and @zoom_level >= 0),
			#:show_grid => @show_grid,
			#:background => @overlay ? true : false

		if @overlay then
			@overlay.draw :target => cairo,
				#:tile_size => @tile_size,
				:offset => @offset + @overlay_offset + center,
				#:show_grid => @show_grid,
				:alpha => (@drag and @dragmode == :overlay) ? 0.5 : 0.7
		end
	end



	def clear
		#@base = HavenMap::Map.new
		#@offset = HavenMap::Coords.new

		#@overlay = nil
		#@overlay_position = Coords.new
		#@overlay_offset = Coords.new

		#@zoom_level = 0
	end


	#def base= base
		#if base.nil? then
			#@base = HavenMap::Map.new
		#else
			#@base = base
		#end

		#redraw
	#end
	
	def resource tiles = []
		# TODO (coords[], layer) version
		# TODO remove tiles from layer
		tiles.map do |tile|
			coords = tile.coords
			layer = tile.layer

			current = Tile.current.all coords: coords, layer: layer
			target = Tile.all coords: coords,
				source: { status: :merged },
				layer: layer,
				limit: 1,
				order: :date.desc

			current.update current: false

			target[0].update current: true if target[0]

			target[0]
		end
	end

	def select_source
		@mode = :select
		@select = :source
		@select_coords = nil
	end

	def read_source
		tile = @layers[@layer].tilemap[@select_coords.to_s]
		if tile
			@source = tile.source
			@source_layer = HavenMap::Layer.new tiles: @source.tiles
			@mode = :source
			@source_toolbar.show
		else
			@mode = @basemode
			@source_toolbar.hide
		end
	end
	
	def source= source
		@source = source
	end

	def source_close
		@mode = @basemode
		@source_toolbar.hide
		redraw
	end

	def source_revert
		tiles = nil
		Tile.transaction do
			@source.update status: :unmerged
			tiles = resource @source.tiles
		end
		@layers[@layer].retile tiles
		source_close
	end

	def source_discard
		tiles = nil
		Tile.transaction do
			@source.update status: :discarded
			tiles = resource @source.tiles
		end
		@layers[@layer].retile tiles
		source_close
	end


	def overlay= overlay
		@overlay = overlay
		@overlay_position = Coords.new
		@overlay_offset = Coords.new
		redraw
	end

	def overlay_move dir
		@overlay_position += dir
		@overlay_offset = @overlay_position * @tile_size
		redraw
	end





	def show_source
		@show_source = true
		redraw
	end

	def show_source= val
		@show_source = val
		redraw
	end

	def hide_source
		@show_source = false
		redraw
	end

	def show_source?
		return @show_source
	end



	def show_grid
		@show_grid = true
		redraw
	end

	def show_grid= val
		@show_grid = val
		redraw
	end

	def hide_grid
		@show_grid = false
		redraw
	end

	def show_grid?
		return @show_grid
	end
end # class MapHandler

end # module HavenMap
