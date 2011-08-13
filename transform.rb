class Transform
	def initialize(scale, rotation, origin)
		@origin = origin
		@scale = scale
		@rotation = sin(rotation * PI / 180.0)
	end

	def apply(component)
		@origin + component * @scale
	end
end

