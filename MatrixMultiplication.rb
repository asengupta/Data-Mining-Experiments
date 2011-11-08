require 'rubygems'
require 'statsample'
require 'benchmark'

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

def product(a,b)
	if a.row_size == 2
		return Matrix.rows([
		[a[0,0]*b[0,0] + a[0,1]*b[1,0], a[0,0]*b[0,1] + a[0,1]*b[1,1]], 
		[a[1,0]*b[0,0] + a[1,1]*b[1,0], a[1,0]*b[0,1] + a[1,1]*b[1,1]]])
	end
#	tp00 = Thread.new{ Thread.current[:result] = product(a.block(0,0), b.block(0,0)) + product(a.block(0,1), b.block(1,0))}
#	tp01 = Thread.new{ Thread.current[:result] = product(a.block(0,0), b.block(0,1)) + product(a.block(0,1), b.block(1,1))}
#	tp10 = Thread.new{ Thread.current[:result] = product(a.block(1,0), b.block(0,0)) + product(a.block(1,1), b.block(1,0))}
#	tp11 = Thread.new{ Thread.current[:result] = product(a.block(1,0), b.block(0,1)) + product(a.block(1,1), b.block(1,1))}
	
	p00 = product(a.block(0,0), b.block(0,0)) + product(a.block(0,1), b.block(1,0))
	p01 = product(a.block(0,0), b.block(0,1)) + product(a.block(0,1), b.block(1,1))
	p10 = product(a.block(1,0), b.block(0,0)) + product(a.block(1,1), b.block(1,0))
	p11 = product(a.block(1,0), b.block(0,1)) + product(a.block(1,1), b.block(1,1))

#	tp00.join
#	tp01.join
#	tp10.join
#	tp11.join

#	Matrix.rows(join(tp00[:result], tp01[:result]) + join(tp10[:result], tp11[:result]))
	Matrix.rows(join(p00, p01) + join(p10, p11))
end

def join(left_block, right_block)
	rows = []
	lower_order = left_block.row_size
	lower_order.times do |t|
		rows << left_block.row(t).to_a + right_block.row(t).to_a
	end
	rows
end

order = 128
m1 = Matrix.build(order, order) {|row, col| rand }
m2 = Matrix.build(order, order) {|row, col| rand }
#m1 = Matrix.rows([
#			[1,2,3,4], 
#			[3,5,4,5], 
#			[13,25,14,15], 
#			[23,25,14,5]
#		])
#m2 = Matrix.rows([
#			[12,13,12,7], 
#			[14,15,4,6],
#			[4,5,14,6],
#			[9,5,8,1]
#		])


threaded_time = Benchmark.measure do
	product(m1,m2)
end
puts "Threaded version = #{threaded_time}"

unthreaded_time = Benchmark.measure do
	m1*m2
end
puts "Unthreaded version = #{unthreaded_time}"

