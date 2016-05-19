# encoding: utf-8

# this stays until alpha development is done
def timer label, opts = {}
	puts "#{label} start" if opts[:showstart]
	time_start = Time.now
	yield
	puts "#{label} time: #{Time.now - time_start}s"
end

module HavenMap

ROOT = File.expand_path '../..', File.dirname(__FILE__)

def self.resource (f)
	File.join ROOT, 'res', f
end

#def self.file (f)
	#catch :file do
		#$LOAD_PATH.each do |dir|
			#file = File.join(dir, 'mikan', f)
			#throw :file, file if File.exists? file
		#end
	#end
#end

end
