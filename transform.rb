class Transform
	attr_accessor :scale, :origin
	def initialize(scale, origin)
		@origin = origin
		@scale = scale
	end

	def apply(p)
		{ :x => @origin[:x] + p[:x] * @scale[:x], :y => @origin[:y] + p[:y] * @scale[:y]}
	end
end

