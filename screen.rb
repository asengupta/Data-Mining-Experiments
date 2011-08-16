require 'transform'

class Screen
	def initialize(transform, artist)
		@transform = transform
		@artist = artist
	end

	def plot(point, basis)
		standard_point = basis.standard_basis(point)
		p = @transform.apply(standard_point)
		@artist.ellipse(p[:x], p[:y], 5, 5)
	end

	def draw_ticks(ticks, displacement)
		ticks.each do |l|
			from = @transform.apply(l[:from])
			to = @transform.apply(l[:to])
			@artist.line(from[:x],from[:y],to[:x],to[:y])
			@artist.fill(1)
			@artist.text(l[:label], to[:x]+displacement[:x], to[:y]+displacement[:y])
		end
	end

	def draw_axes(basis, x_interval, y_interval)
		f = @artist.createFont("Georgia", 24, true);
		@artist.text_font(f,16)
		@artist.stroke(1,1,1,1)
		axis_screen_transform = Transform.new({:x => 800, :y => -800}, @transform.origin)
		origin = {:x => 0, :y => 0}
		screen_origin = @transform.apply(origin)
		x_basis_edge = axis_screen_transform.apply(basis.x_basis_vector)
		y_basis_edge = axis_screen_transform.apply(basis.y_basis_vector)
		@artist.line(screen_origin[:x],screen_origin[:y],x_basis_edge[:x],x_basis_edge[:y])
		@artist.line(screen_origin[:x],screen_origin[:y],y_basis_edge[:x],y_basis_edge[:y])

		draw_ticks(basis.x_ticks(x_interval), {:x => 0, :y => 20})
		draw_ticks(basis.y_ticks(y_interval), {:x => -50, :y => 0})
	end
end

