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

	def run(interval)
		current = @minimum
		while(current <= @maximum)
			yield(current,current)
			current += interval
		end
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

	def run(interval)
		current = 0
		while(current <= @values.count - 1)
			yield(current,@values[current])
			current += interval
		end
	end
end

