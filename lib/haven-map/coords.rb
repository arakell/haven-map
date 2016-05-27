# encoding: utf-8
#
require 'data_mapper'

module DataMapper
	class Property
		class Coords < String
			length 13

			def custom?
				true
			end

			def load value
				HavenMap::Coords.parse value
			end

			def dump value
				value.to_s unless value.nil?
			end

			def typecast_to_primitive value
				load value
			end

		end
	end
end



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
		if b.is_a? Fixnum
			Coords.new @x + b, @y + b
		elsif b.is_a? Coords
			Coords.new @x + b.x, @y + b.y
		end
	end

	def - b
		if b.is_a? Fixnum
			Coords.new @x - b, @y - b
		elsif b.is_a? Coords
			Coords.new @x - b.x, @y - b.y
		end
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

	def round
		Coords.new @x.round.to_i, @y.round.to_i
	end

	def ceil
		Coords.new @x.ceil, @y.ceil
	end

	def floor
		Coords.new @x.floor, @y.floor
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

	def self.parse value
		return value if value.kind_of? Coords
		(x, y) = value.split(/,/)
		Coords.new x, y
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

	def to_s
		"#{min}/#{max}"
	end
end

end # module HavenMap
