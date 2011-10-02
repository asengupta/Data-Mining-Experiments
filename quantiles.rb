module Quantiles
	def self.quantile(p)
	end
	
	def self.erf_inverse(x)
		a = 0.147
		common_term = (2/(Math::PI * a)) + Math.log(1.0 - x**2)
		term2 = Math.log(1.0 - x**2)/a
		(x<=>0.0) * Math.sqrt(Math.sqrt(common_term**2 - term2) - common_term)
	end
	
	def self.quantile_normal(mean, variance)
		lambda {|p| mean + Math.sqrt(2 * variance) * erf_inverse(2 * p - 1.0)}
	end

	def self.quantile_cauchy(location, scale)
		lambda {|p| location + scale * Math.tan(Math::PI*(p - 0.5))}
	end
end

