require 'set'
require 'schema'
require 'ranges'
require 'transform'
require 'coordinate_system'
require 'ruby-processing'

class MySketch < Processing::App
	app = self
	def setup
		@screen_height = 900
		@width = width
		@height = height
		@screen_transform = Transform.new({:x => 1, :y => -1}, {:x => 300, :y => @screen_height})
		frame_rate(30)
		smooth
		background(0,0,0)
		color_mode(RGB, 1.0)

		responses = Response.find(:all)

		pre_bins = []
		post_bins = []

		56.times {pre_bins << 0}
		56.times {post_bins << 0}

		56.times do |pre_score|
			pre_bins[pre_score] = responses.select {|r| r.pre_total == pre_score}.count
		end
		56.times do |post_score|
			post_bins[post_score] = responses.select {|r| r.post_total == post_score}.count
		end

		@x_unit_vector = {:x => 1.0, :y => 0.3}
		@y_unit_vector = {:x => -0.3, :y => 1.0}

		x_range = ContinuousRange.new({:minimum => 0, :maximum => 56})
		y_range = ContinuousRange.new({:minimum => 0, :maximum => 2000})
		x_scale = @width / x_range.interval
		y_scale = @height / y_range.interval

		@c = CoordinateSystem.new(Axis.new(@x_unit_vector,x_range), Axis.new(@y_unit_vector,y_range), [[10,0],[0,0.4]])
		draw_axes
		stroke(1,1,0,1)
		fill(1,1,0)
		pre_bins.each_index do |position|
			standard_point = @c.standard_basis({:x => position, :y => pre_bins[position]})
			p = @screen_transform.apply(standard_point)
			ellipse(p[:x], p[:y], 5, 5)
		end

		stroke(0,1,0,1)
		fill(0,1,0)
		post_bins.each_index do |position|
			standard_point = @c.standard_basis({:x => position, :y => post_bins[position]})
			p = @screen_transform.apply(standard_point)
			ellipse(p[:x], p[:y], 5, 5)
		end
	end
	  
	def draw_axes
		f = createFont("Georgia", 24, true);
		text_font(f,16)
		stroke(1,1,1,1)
		screen_transform = Transform.new({:x => 800, :y => -800}, {:x => 300, :y => @screen_height})
		origin = {:x => 0, :y => 0}
		screen_origin = screen_transform.apply(origin)
		x_basis_edge = screen_transform.apply(@x_unit_vector)
		y_basis_edge = screen_transform.apply(@y_unit_vector)
		line(screen_origin[:x],screen_origin[:y],x_basis_edge[:x],x_basis_edge[:y])
		line(screen_origin[:x],screen_origin[:y],y_basis_edge[:x],y_basis_edge[:y])
		@c.x_ticks(4).each do |l|
			from = @screen_transform.apply(l[:from])
			to = @screen_transform.apply(l[:to])
			line(from[:x],from[:y],to[:x],to[:y])
			fill(1)
			text(l[:label], to[:x], to[:y]+20)
		end
		@c.y_ticks(50).each do |l|
			from = @screen_transform.apply(l[:from])
			to = @screen_transform.apply(l[:to])
			line(from[:x],from[:y],to[:x],to[:y])
			fill(1)
			text(l[:label], to[:x]-50, to[:y])
		end
	end

	def draw
	end
end

w = 1200
h = 1000

MySketch.new(:title => "My Sketch", :width => w, :height => h)


