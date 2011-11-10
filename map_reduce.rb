class Partitioner
	def run(space)
		partitions = {}
		space.each do |i|
			key = i[:key]
			partitions[key] = [] if partitions[key].nil?
			partitions[key] << i[:value]
		end
		partitions
	end
end

class Reducer
	def run(partitions)
		space = []
		partitions.each_pair do |k,v|
			space << yield(k,v)
		end
		space
	end
end

class Mapper
	def run(space)
		space.collect {|i| yield(i[:key], i)}
	end
end

