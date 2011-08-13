class ContinuousRange
	attr_accessor :minimum, :maximum

	def initialize(range)
		@minimum = range[:minimum]
		@maximum = range[:maximum]
	end

	def interval
		@maximum - @minimum
	end

	def index(element)
		element.to_f
	end
end

class DiscreteRange
	attr_accessor :values
	def initialize(v)
		@values = v[:values]
	end

	def interval
		@values.count
	end

	def index(element)
		@values.index(element)
	end
end

