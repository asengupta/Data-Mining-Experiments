require 'ranges'

include Math

def into2Dx2D(first, second)
	[
		[second[0][0]*first[0][0] + second[1][0]*first[0][1], second[0][1]*first[0][0] + second[1][1]*first[0][1]],
		[second[0][0]*first[1][0] + second[1][0]*first[1][1], second[0][1]*first[1][0] + second[1][1]*first[1][1]]
	]
end

def into2Dx1D(transform, point)
	{
		:x => transform[0][0]*point[:x] + transform[0][1]*point[:y], 
		:y => transform[1][0]*point[:x] + transform[1][1]*point[:y]
	}
end

class Axis
	attr_accessor :basis_vector, :range
	def initialize(basis_vector, range)
		@basis_vector = basis_vector
		@range = range
	end
end

class CoordinateSystem
	def initialize(x_axis, y_axis, transform)
		@x_axis = x_axis
		@y_axis = y_axis
		@x_basis_vector = x_axis.basis_vector
		@y_basis_vector = y_axis.basis_vector
		@basis_transform = transform
		@basis_matrix = 
				[
					[@x_basis_vector[:x],@y_basis_vector[:x]],
					[@x_basis_vector[:y],@y_basis_vector[:y]]
				]

		d = @basis_matrix[0][0]*@basis_matrix[1][1] - @basis_matrix[0][1]*@basis_matrix[1][0]
		@inverse_basis = 
				[
					[@basis_matrix[1][1]/d, -@basis_matrix[0][1]/d],
					[-@basis_matrix[1][0]/d, @basis_matrix[0][0]/d]
				]

		@standard_transform = into2Dx2D(into2Dx2D(@basis_matrix, @basis_transform), @inverse_basis)
	end

	def tick_vectors
		unnormalised_vectors =
		{
			:x_tick_vector => into2Dx1D(rotation(-90),@x_basis_vector),
			:y_tick_vector => into2Dx1D(rotation(90),@y_basis_vector)
		}
		{
			:x_tick_vector => normal(unnormalised_vectors[:x_tick_vector]),
			:y_tick_vector => normal(unnormalised_vectors[:y_tick_vector])
		}
	end

	def normal(vector)
		magnitude = sqrt(vector[:x]**2 + vector[:y]**2)
		{:x => 5*vector[:x]/magnitude, :y => 5*vector[:y]/magnitude}
	end

	def sum(v1, v2)
		{:x => v1[:x] + v2[:x], :y => v1[:y] + v2[:y]}
	end

	def x_ticks(x_basis_interval)
		lines = []
		t_vectors = tick_vectors
		@x_axis.range.run(x_basis_interval) do |i,v|
			tick_origin = standard_basis({:x => i, :y => 0})
			lines << {:label => v, :from => tick_origin, :to => sum(tick_origin, t_vectors[:x_tick_vector])}
		end
		lines
	end

	def y_ticks(y_basis_interval)
		lines = []
		t_vectors = tick_vectors
		@y_axis.range.run(y_basis_interval) do |i,v|
			tick_origin = standard_basis({:x => 0, :y => i})
			lines << {:label => v, :from => tick_origin, :to => sum(tick_origin, t_vectors[:y_tick_vector])}
		end
		lines
	end

	def rotation(angle)
		radians = angle * PI/180.0
		[[cos(radians), -sin(radians)],[sin(radians),cos(radians)]]
	end

	def standard_basis(point)
		standard_point =
		{
			:x => @x_basis_vector[:x]*point[:x] + @y_basis_vector[:x]*point[:y], 
			:y => @x_basis_vector[:y]*point[:x] + @y_basis_vector[:y]*point[:y]
		}

		into2Dx1D(@standard_transform, standard_point)
	end
end

