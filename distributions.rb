module Distributions
	def self.normal(mean, variance)
		lambda {|x| 1.0/(Math.sqrt(2.0 * Math::PI * variance)) * Math.exp(-((x - mean)**2) / (2 * variance))}
	end

	def self.cauchy(location, scale)
		lambda {|x| 1.0/Math::PI * scale / ((x - location)**2 + scale**2)}
	end

	def self.poisson(lamb)
		lambda {|k| lamb**k * Math.exp(-lamb) / factorial(k)}
	end

	def self.log_normal(location, scale)
		lambda {|x| 1.0/(x * scale * Math.sqrt(2 * Math::PI)) * Math.exp(-((Math.log(x) - location)**2) / (2 * scale**2))}
	end

	def self.factorial(n)
		raise "You suck" if n <= 0
		return 1 if n == 1
		return n * factorial(n - 1)
	end
end

