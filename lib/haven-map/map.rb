require 'haven-map/layer'
require 'haven-map/coords'

module HavenMap

class Map
	attr_reader :overlay_position

	def initialize widget, args = {}
		clear

		@widget = widget
		@options = args
		@base = args[:base] ? args[:base] : Layer.new
		@tile_size = @base_tile_size = args[:tile_size]

		connect_events
	end

	def connect_events
		@widget.signal_connect 'button-press-event' do |widget, event|
			if event.button == 1 then
				@drag = Coords.new event
				@dragmode = :offset
			elsif event.button == 3 and @overlay then
				@drag = Coords.new event
				@dragmode = :overlay
			else
				@dragmode = nil
			end
		end

		@widget.signal_connect 'button-release-event' do |widget, event|
			if @drag and @dragmode == :overlay then
				@overlay_position = @overlay_offset.rdiv @tile_size
				@overlay_offset = @overlay_position * @tile_size
				redraw
			end
			@drag = nil
		end

		@widget.signal_connect 'motion-notify-event' do |widget, event|
			if @drag then
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


		@widget.signal_connect 'scroll-event' do |widget, event|
			size = @widget.allocation
			center = Coords.new(event.x - size.width / 2, event.y - size.height / 2)
			if event.direction == Gdk::ScrollDirection::UP then
				zoom @zoom_level + 1, center
			elsif event.direction == Gdk::ScrollDirection::DOWN then
				zoom @zoom_level - 1, center
			end
		end


		@widget.signal_connect 'draw' do
			draw
		end
	end

	def redraw
		@widget.queue_draw if @widget
	end

	def zoom level, center = Coords.new
		return if !@options[:zoom]

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

	def draw
		@base.draw :target => @widget,
			:tile_size => @tile_size,
			:offset => @offset,
			:show_source => (@show_source and @zoom_level >= 0),
			:show_grid => @show_grid,
			:background => @overlay ? true : false

		if @overlay then
			@overlay.draw :target => @widget,
				:tile_size => @tile_size,
				:offset => @offset + @overlay_offset,
				:show_grid => @show_grid,
				:alpha => (@drag and @dragmode == :overlay) ? 0.5 : 0.7
		end
	end

	def drag
	end



	def clear
		@base = HavenMap::Map.new
		@offset = HavenMap::Coords.new

		@overlay = nil
		@overlay_position = Coords.new
		@overlay_offset = Coords.new

		@zoom_level = 0
	end


	def base= base
		if base.nil? then
			@base = HavenMap::Map.new
		else
			@base = base
		end

		redraw
	end

	def overlay= overlay
		@overlay = overlay
		@overlay_position = Coords.new
		@overlay_offset = Coords.new
		redraw
	end

	def overlay_move dir
		puts "before: #{@overlay_position}"
		@overlay_position += dir
		puts "after: #{@overlay_position}"
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
