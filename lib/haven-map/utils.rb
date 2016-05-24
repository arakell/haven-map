# encoding: utf-8

class Hash
	def transform_keys
		return enum_for(:transform_keys) unless block_given?
		result = self.class.new
		each_key do |key|
			result[yield(key)] = self[key]
		end
		result
	end
	def transform_keys!
		return enum_for(:transform_keys!) unless block_given?
		keys.each do |key|
			self[yield(key)] = delete(key)
		end
		self
	end
	def symbolize_keys
		transform_keys{ |key| key.to_sym rescue key }
	end
	def symbolize_keys!
		transform_keys!{ |key| key.to_sym rescue key }
	end
end


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
