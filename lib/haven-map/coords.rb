# encoding: utf-8

module HavenMap

class Coords
	attr_reader :x, :y

	def initialize x = nil, y = nil
		if x.nil?
			@x = 0
			@y = 0
		elsif y.nil?
			@x = x.x
			@y = x.y
		else
			@x = x.to_i
			@y = y.to_i
		end
	end

	def reset b
		@x = b.x
		@y = b.y
	end

	def + b
		Coords.new @x + b.x, @y + b.y
	end

	def - b
		Coords.new @x - b.x, @y - b.y
	end

	def * b
		Coords.new @x * b, @y * b
	end

	def / b
		Coords.new @x / b, @y / b
	end

	def fdiv b
		Coords.new @x.to_f / b, @y.to_f / b
	end

	def rdiv b
		Coords.new((@x.to_f / b).round.to_i, (@y.to_f / b).round.to_i)
	end

	def min b
		Coords.new([@x, b.x].min, [@y, b.y].min)
	end

	def max b
		Coords.new([@x, b.x].max, [@y, b.y].max)
	end

	def min! b
		@x = [@x, b.x].min
		@y = [@y, b.y].min
	end

	def max! b
		@x = [@x, b.x].max
		@y = [@y, b.y].max
	end

	def to_s
		"#{@x},#{@y}"
	end
end # class Coords

class Bounds
	attr_accessor :min, :max

	def initialize min = nil, max = nil
		@min = min || Coords.new(0,0)
		@max = min || Coords.new(0,0)
	end

	def size
		@max - @min
	end

	def width
		size.x
	end

	def height
		size.y
	end

	def expand! coords
		@min.min! coords
		@max.max! coords
	end
end

end # module HavenMap
