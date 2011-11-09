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

def product(a,b,level)
	result = nil
	if a.row_size == 16
		time = Benchmark.measure do
			result = a * b
		end
#		puts "\t"*level + "Low level #{UUID.new} finished in #{time}"
		return result
	end
	time = Benchmark.measure do
		next_level = level + 1
		tp00 = Thread.new{ Thread.current[:result] = product(a.block(0,0), b.block(0,0), next_level) + product(a.block(0,1), b.block(1,0), next_level)}
		tp01 = Thread.new{ Thread.current[:result] = product(a.block(0,0), b.block(0,1), next_level) + product(a.block(0,1), b.block(1,1), next_level)}
		tp10 = Thread.new{ Thread.current[:result] = product(a.block(1,0), b.block(0,0), next_level) + product(a.block(1,1), b.block(1,0), next_level)}
		tp11 = Thread.new{ Thread.current[:result] = product(a.block(1,0), b.block(0,1), next_level) + product(a.block(1,1), b.block(1,1), next_level)}
	
#		p00 = product(a.block(0,0), b.block(0,0)) + product(a.block(0,1), b.block(1,0))
#		p01 = product(a.block(0,0), b.block(0,1)) + product(a.block(0,1), b.block(1,1))
#		p10 = product(a.block(1,0), b.block(0,0)) + product(a.block(1,1), b.block(1,0))
#		p11 = product(a.block(1,0), b.block(0,1)) + product(a.block(1,1), b.block(1,1))

		tp00.join
		tp01.join
		tp10.join
		tp11.join

		result = Matrix.rows(join(tp00[:result], tp01[:result]) + join(tp10[:result], tp11[:result]))
#		result = Matrix.rows(join(p00, p01) + join(p10, p11))
	end
#	puts "\t"*level + "#{UUID.new} finished in #{time}" if level == 1
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

order = 64

m1 = m(order)
m2 = m(order)

threaded = nil
normal = nil
unthreaded_time = Benchmark.measure do
	normal = m1*m2
end
puts "Unthreaded version = #{unthreaded_time}"

threaded_time = Benchmark.measure do
	threaded = product(m1,m2,0)
end
puts "Threaded version = #{threaded_time}"


puts threaded == normal

