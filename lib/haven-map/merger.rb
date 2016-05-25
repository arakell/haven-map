# encoding: utf-8
#
require 'haven-map/source'
require 'set'

module HavenMap

class Merger
	attr_writer :map, :mergebar

	def initialize args = {}
		@map = args[:map]
		@basedir = Pathname.new(args[:path])
		@active = false
	end

	def read_source_dir dir, sourcemap
		Dir.entries(@basedir + dir).
			select{|d| d[0] != '.' and Dir.exists? @basedir + dir + d }.
			select{|d| !sourcemap.include? "#{dir}/#{d}"}.
			sort
	end

	def read_sources
		sources = Source.all
		sourcemap = sources.map { |s| s.path }.to_set

		read_source_dir('map', sourcemap).each do |dir|
			source = Source.new
			source.path = "map/#{dir}"
			source.type = :surface
			source.date = DateTime.parse dir

			sources.push source
			source.save
		end

		read_source_dir('cave', sourcemap).each do |dir|
			source = Source.new
			source.path = "cave/#{dir}"
			source.type = :cave
			source.date = DateTime.parse dir

			sources.push source
			source.save
		end

		@sources = sources.sorted.unmerged
	end

	def toggle
		if @active
			stop
		else
			start
		end
	end

	def start
		return if @active

		read_sources

		@mergebar.show
		@active = true

		self.next
	end

	def stop
		return if !@active

		@mergebar.hide
		@active = false
	end

	def merge
		return if !@source

		layer = @map.layer
		oldtiles = @map.layers[layer].tilemap
		
		@source.tiles.each do |tile|
			target = tile.coords + @merge_offset
			oldtile = oldtiles[tile.coords]
			oldtile.update current: false if oldtile
			tile.attributes coords: target, current: true, layer: layer
			ap tile
			tile.save
			#puts "would merge #{tile.coords} to #{target}"
		end

		@map.layers[layer].retile @source.tiles

		#@source.update status: :merged
		self.next
	end

	def next
		@source = @sources.shift
		return stop if !@source

		@source.read_tiles @basedir
		ap @source.tiles
		layer = HavenMap::Layer.new tiles: @source.tiles

		@merge_offset = Coords.new
		@map.merge @source.type, layer do |offset|
			@merge_offset = offset
		end
	end

	def discard
		return if !@source
		@source.update status: :discarded
		self.next
	end

	def edit
	end

	def restart
		read_sources
		self.next
	end

end # class Merger

end # module HavenMap
