class Transform
	def initialize(scale, origin)
		@origin = origin
		@scale = scale
	end

	def apply(component)
		@origin + component * @scale
	end
end

