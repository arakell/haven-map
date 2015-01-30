# encoding: utf-8
# TODO

require 'xdg'
require 'yaml'
require 'optparse'
require 'pathname'

module HavenMap

class Config < Hash
	VERSION='1.0'
	APPNAME='kaiju'

	def initialize extra = {}
		merge!({
			:config        => "#{XDG['CONFIG_HOME'].to_s}/#{APPNAME}/config.yaml",
			:db            => "#{XDG['DATA_HOME'].to_s}/#{APPNAME}/local.sqlite3",
			:server        => "http://jira.xtm-intl.com",
			:columns       => [],
			:typeLabel     => false,
			:priorityLabel => false,
			:statusLabel   => true,
			#issues: "http://jira.xtm-intl.com/browse/"
			:verbose       => false
		})
		merge! extra

		cli = {}
		OptionParser.new do |opts|
			opts.version = '1.0'
			opts.banner = "Usage: " + opts.program_name + " [options] [search]"

			yield opts, cli if block_given?

			opts.separator ""
			opts.separator "Specific options:"

			opts.on "--config=FILE", "Use a non-default config file" do |val|
				   options[:config] = val
			end

			opts.on "--db=FILE", "Use a non-default local database file" do |val|
				   options[:db] = val
			end

			opts.separator ""
			opts.separator "Common options:"

			opts.on("-v", "--[no-]verbose", "Run verbosely") do |val|
				cli[:verbose] = val
			end

			opts.on("--debug", "Debug") do |val|
				cli[:debug] = val
			end

			opts.on_tail "-h", "--help", "Show this message" do
				puts opts
				exit
			end

			opts.on_tail "--version", "Show version" do
				puts opts.ver()
				exit
			end
		end.parse!
		tmp = merge cli



		if File.exists? tmp[:config]
			#conf = YAML::load_file self[:config]
			#ap conf
			#ap conf.symbolize_keys
			#ap self
			#ap merge conf.symbolize_keys
			#exit
			merge! YAML::load_file(self[:config]).symbolize_keys!
		end
		merge! cli
	end

	def get key = nil
		key ? self[key] : self
	end

	def save
		Pathname.new(self[:config]).dirname.mkpath
		#ap self.stringify_keys.to_yaml
		File.open(self[:config], "w") do |f|
		    YAML.dump self.select{|k,v| ![:config].include? k }.stringify_keys, f
		end
		#puts YAML::dump(self.stringify_keys)
	end

end # class Config

end # module HavenMap
