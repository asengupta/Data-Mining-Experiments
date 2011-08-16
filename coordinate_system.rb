require 'ranges'
require 'ruby-processing'
require 'matrix_operations'

include Math

class Axis
	attr_accessor :basis_vector, :range
	def initialize(basis_vector, range)
		@basis_vector = basis_vector
		@range = range
	end
end

class CoordinateSystem
	include MatrixOperations
	def initialize(x_axis, y_axis, transform, artist)
		@artist = artist
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

		@standard_transform = MatrixOperations::into2Dx2D(MatrixOperations::into2Dx2D(@basis_matrix, @basis_transform), @inverse_basis)
	end

	def tick_vectors
		unnormalised_vectors =
		{
			:x_tick_vector => MatrixOperations::into2Dx1D(rotation(-90),@x_basis_vector),
			:y_tick_vector => MatrixOperations::into2Dx1D(rotation(90),@y_basis_vector)
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

	def draw_axes(screen_transform)
		f = @artist.createFont("Georgia", 24, true);
		@artist.text_font(f,16)
		@artist.stroke(1,1,1,1)
		axis_screen_transform = Transform.new({:x => 800, :y => -800}, screen_transform.origin)
		origin = {:x => 0, :y => 0}
		screen_origin = screen_transform.apply(origin)
		x_basis_edge = axis_screen_transform.apply(@x_basis_vector)
		y_basis_edge = axis_screen_transform.apply(@y_basis_vector)
		@artist.line(screen_origin[:x],screen_origin[:y],x_basis_edge[:x],x_basis_edge[:y])
		@artist.line(screen_origin[:x],screen_origin[:y],y_basis_edge[:x],y_basis_edge[:y])
		
		draw_ticks(x_ticks(4), screen_transform, {:x => 0, :y => 20})
		draw_ticks(y_ticks(50), screen_transform, {:x => -50, :y => 0})
	end

	def draw_ticks(ticks, screen_transform, displacement)
		ticks.each do |l|
			from = screen_transform.apply(l[:from])
			to = screen_transform.apply(l[:to])
			@artist.line(from[:x],from[:y],to[:x],to[:y])
			@artist.fill(1)
			@artist.text(l[:label], to[:x]+displacement[:x], to[:y]+displacement[:y])
		end
	end

	def standard_basis(point)
		standard_point =
		{
			:x => @x_basis_vector[:x]*point[:x] + @y_basis_vector[:x]*point[:y], 
			:y => @x_basis_vector[:y]*point[:x] + @y_basis_vector[:y]*point[:y]
		}

		MatrixOperations::into2Dx1D(@standard_transform, standard_point)
	end
end

