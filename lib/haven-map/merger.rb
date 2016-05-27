# encoding: utf-8
#
require 'haven-map/source'
require 'set'

module HavenMap

class Merger
	attr_writer :map, :mergebar, :count, :backlog_count, :backlog_buttons

	def initialize args = {}
		@map = args[:map]
		@basedir = Pathname.new(args[:path])
		@active = false
		@backlog = []
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

		Source.transaction do

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

		@map.unmerge

		@mergebar.hide
		@active = false
		@backlog = []
	end

	def merge
		return if !@source

		layer = @map.layer

		Tile.transaction do
			@map.layers[layer].merge @source, @merge_offset
			@source.update status: :merged
		end
		self.next
	end

	def merge_backlog
		return if @backlog.empty?

		Tile.transaction do
			@backlog.each do |log|
				@map.layers[log[:layer]].merge log[:source], log[:offset]
				log[:source].update status: :merged
			end
		end

		@backlog = []
		@backlog_count.label = '0'
	end
	
	def skip
		self.next
	end

	def cache
		@backlog.push({
			layer: @map.layer,
			offset: @merge_offset,
			source: @source
		})
		self.next
	end

	def previous
		return if @backlog.empty?

		@sources.unshift @source
		log = @backlog.pop

		@source = log[:source]
		@merge_offset = log[:offset]

		@count.label = @sources.length.to_s
		@backlog_count.label = @backlog.length.to_s

		layer = HavenMap::Layer.new tiles: @source.tiles

		@map.merge @source.type, layer do |offset|
			@merge_offset = offset
		end
	end

	def next
		@source = @sources.shift

		puts "source: #{@source}"

		return stop if !@source

		@count.label = @sources.length.to_s
		@backlog_count.label = @backlog.length.to_s

		@source.read_tiles @basedir
		if @source.tiles.length < 9
			return discard
		end

		layer = HavenMap::Layer.new tiles: @source.tiles

		@merge_offset = Coords.new
		@map.merge @source.type, layer do |offset|
			@merge_offset = offset
		end
	end

	def discard
		return if !@source
		@source.reload
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
