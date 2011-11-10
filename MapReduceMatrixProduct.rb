require 'rubygems'
require 'statsample'
require './matrix_block_mixin'
require './map_reduce'

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

def block_join_reduce(key, values)
	p00 = values[values.index {|v| v[:identity] == '00'}][:matrix]
	p01 = values[values.index {|v| v[:identity] == '01'}][:matrix]
	p10 = values[values.index {|v| v[:identity] == '10'}][:matrix]
	p11 = values[values.index {|v| v[:identity] == '11'}][:matrix]
	{:key => key[0..-2], :value => {:identity => key[-1], :matrix => Matrix.rows(join(p00, p01) + join(p10, p11))}}
end

def block_matrix_sum(key, values)
	sum = Matrix.zero(values.first[:matrix].row_size)
	values.each {|m| sum += m[:matrix]}
	{:key => key[0..-3], :value => {:matrix => sum, :identity => key[-2..-1]}}
end

def primitive_map(key, value)
	{:key => key[0..-2], :value =>  {:matrix => value[:a] * value[:b], :identity => key[0..-2]}}
end

order = 128
reductions = (Math.log2(order) - 1).to_i
m1 = m(order)
m2 = m(order)

inputs = Inputs.new
inputs.setup(m1,m2,"X")
space = inputs.inputs


mappers = [->(k,v) {primitive_map(k,v)}]
reducers = []

reductions.times do
	reducers << ->(k,v) {block_matrix_sum(k,v)}
	reducers << ->(k,v) {block_join_reduce(k,v)}
end

result = MapReduceRunner.new(mappers, reducers).run(space)
puts result
puts result[0][:value][:matrix]
puts m1*m2 == result[0][:value][:matrix]

