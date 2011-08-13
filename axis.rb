require 'transform'

class Axis
	attr_accessor :basis_vector

	def initialize(span, range, origin, sign, basis_vector)
		@span = span
		@range = range
		@basis_vector = basis_vector
		@transform = Transform.new((sign<=>0.0) * @span / range.interval.to_f, origin)
	end

	def transform(component)
		@transform.apply(component)
	end

	def index(element)
		@range.index(element)
	end
end

class CoordinateSystem
	def initialize(x_basis_vector, y_basis_vector)
		@x_basis_vector = x_basis_vector
		@y_basis_vector = y_basis_vector
	end

	def standard_basis(point)
		standard_point =
		{
			:x => @x_basis_vector.basis_vector[:x]*point[:x] + @y_basis_vector.basis_vector[:x]*point[:y], 
			:y => @x_basis_vector.basis_vector[:y]*point[:x] + @y_basis_vector.basis_vector[:y]*point[:y]
		}

		{:x => @x_basis_vector.transform(standard_point[:x]), :y => @y_basis_vector.transform(standard_point[:y])}
	end
end

