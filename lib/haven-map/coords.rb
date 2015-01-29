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

	def to_s
		"#{@x}×#{@y}"
	end
end # class Coords

end # module HavenMap
