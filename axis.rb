require 'transform'

class Axis
	def initialize(span, range, origin, sign, rotation)
		@span = span
		@range = range
		@transform = Transform.new((sign<=>0.0) * @span / range.interval.to_f, rotation, origin)
	end

	def transform(component)
		@transform.apply(@range.index(component))
	end
end

