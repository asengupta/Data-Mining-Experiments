module MatrixOperations
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


	def standard_basis(point)
		standard_point =
		{
			:x => @x_basis_vector[:x]*point[:x] + @y_basis_vector[:x]*point[:y], 
			:y => @x_basis_vector[:y]*point[:x] + @y_basis_vector[:y]*point[:y]
		}

		MatrixOperations::into2Dx1D(@standard_transform, standard_point)
	end
end

