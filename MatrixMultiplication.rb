require 'rubygems'
require 'statsample'
require 'benchmark'
require 'uuidtools'

class Matrix
	def block(block_row, block_column)
		raise "Non 2^n matrix" if (row_size & (row_size - 1)) != 0 || (column_size & (column_size - 1)) != 0
		lower_order = row_size/2
		start_row = block_row * lower_order
		start_column = block_column * lower_order
		b = []
		lower_order.times do |r|
			row = []
			lower_order.times do |c|
				row << self[start_row + r, start_column + c]
			end
			b << row
		end
		Matrix.rows(b)
	end
end

class Inputs
	attr_accessor :inputs
	def initialize
		@inputs = []
	end

	def setup(a,b,key)
		if a.row_size == 2
			@inputs << {:key=> key, :a => a, :b => b}
			return
		end
		setup(a.block(0,0), b.block(0,0), key + "00A")
		setup(a.block(0,1), b.block(1,0), key + "00B")

		setup(a.block(0,0), b.block(0,1), key + "01A")
		setup(a.block(0,1), b.block(1,1), key + "01B")

		setup(a.block(1,0), b.block(0,0), key + "10A")
		setup(a.block(1,1), b.block(1,0), key + "10B")

		setup(a.block(1,0), b.block(0,1), key + "11A")
		setup(a.block(1,1), b.block(1,1), key + "11B")
	
	end
end


def product(a,b,key)
	result = nil
	if a.row_size == 2
		time = Benchmark.measure do
			result = a * b
		end
#		puts "\t"*key + "Low key #{UUID.new} finished in #{time}"
		return result
	end
	time = Benchmark.measure do
		next_key = key + 1
		p00 = product(a.block(0,0), b.block(0,0)) + product(a.block(0,1), b.block(1,0))
		p01 = product(a.block(0,0), b.block(0,1)) + product(a.block(0,1), b.block(1,1))
		p10 = product(a.block(1,0), b.block(0,0)) + product(a.block(1,1), b.block(1,0))
		p11 = product(a.block(1,0), b.block(0,1)) + product(a.block(1,1), b.block(1,1))

		result = Matrix.rows(join(p00, p01) + join(p10, p11))
	end
#	puts "\t"*key + "#{UUID.new} finished in #{time}" if key == 1
	result
end

def join(left_block, right_block)
	rows = []
	lower_order = left_block.row_size
	lower_order.times do |t|
		rows << left_block.row(t).to_a + right_block.row(t).to_a
	end
	rows
end

def m(order)
	Matrix.build(order, order) {|row, col| rand(20) }
end

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

def reduce2(key, values)
	p00 = values[values.index {|v| v[:identity] == '00'}][:matrix]
	p01 = values[values.index {|v| v[:identity] == '01'}][:matrix]
	p10 = values[values.index {|v| v[:identity] == '10'}][:matrix]
	p11 = values[values.index {|v| v[:identity] == '11'}][:matrix]
	{:key => key[0..-2], :value => {:identity => key[-1], :matrix => Matrix.rows(join(p00, p01) + join(p10, p11))}}
end

def reduce1(key, values)
	sum = Matrix.zero(values.first[:matrix].row_size)
	values.each {|m| sum += m[:matrix]}
	{:key => key[0..-3], :value => {:matrix => sum, :identity => key[-2..-1]}}
end

def map1(key, value)
	{:key => key[0..-2], :value =>  {:matrix => value[:a] * value[:b], :identity => key[0..-2]}}
end

order = 8

m1 = m(order)
m2 = m(order)

inputs = Inputs.new
inputs.setup(m1,m2,"X")
space = inputs.inputs


space = Mapper.new.run(space) {|k,v| map1(k,v)}
partitions = Partitioner.new.run(space)
space = Reducer.new.run(partitions) {|k,v| reduce1(k,v)}
partitions = Partitioner.new.run(space)
space = Reducer.new.run(partitions) {|k,v| reduce2(k,v)}
partitions = Partitioner.new.run(space)
space = Reducer.new.run(partitions) {|k,v| reduce1(k,v)}
partitions = Partitioner.new.run(space)
space = Reducer.new.run(partitions) {|k,v| reduce2(k,v)}

puts space[0][:value][:matrix]
puts m1*m2 == space[0][:value][:matrix]

