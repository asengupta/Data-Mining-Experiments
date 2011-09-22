require 'rubygems'

Gem.clear_paths
ENV['GEM_HOME'] = '/home/avishek/jruby/jruby-1.6.3/lib/ruby/gems/1.8'
ENV['GEM_PATH'] = '/home/avishek/jruby/jruby-1.6.3/lib/ruby/gems/1.8'

require 'schema'
require 'set'
require 'ruby-processing'
require 'basis_processing'
require 'amqp'

include Math

class MySketch < Processing::App
	app = self
	def setup
		frame_rate(30)
		no_loop
		smooth
		background(0,0,0)
		color_mode(HSB, 1.0)

		@old_rectangles = []
		@rectangles_to_highlight = []
		responses = Response.find(:all)
		@bins = []
		57.times do
			answer_distribution = []
			56.times {answer_distribution << 0}
			@bins << answer_distribution
		end
		responses.each do |r|
			bit_string = r[:pre_performance].to_s(2).rjust(56, '0')
			i = 0
			bit_string.each_char do |bit|
				@bins[r[:pre_total]][i] = @bins[r[:pre_total]][i] + 1 if bit == '1'
				i += 1
			end
		end

		sums = []
		57.times {|total| sums << responses.select {|r| r[:pre_total] == total}.count}
		@bins.each_index do |bin_index|
			@bins[bin_index].each_index do |answer_index|
				@bins[bin_index][answer_index] = @bins[bin_index][answer_index]/sums[bin_index].to_f
			end
		end

		@scale = 10

		x_basis_vector = {:x => 1.0, :y => 0.0}
		y_basis_vector = {:x => 0.0, :y => 1.0}

		x_range = ContinuousRange.new({:minimum => 0, :maximum => 56})
		y_range = ContinuousRange.new({:minimum => 0, :maximum => 56})

		@basis = CoordinateSystem.new(Axis.new(x_basis_vector,x_range), Axis.new(y_basis_vector,y_range), [[@scale,0],[0,@scale]], self)
		screen_transform = SignedTransform.new({:x => 1, :y => -1}, {:x => 300, :y => 900})

		@screen = Screen.new(screen_transform, self)
		stroke(0,0,0)
		rect_mode(CENTER)
		@bins.each_index do |bin_index|
			@bins[bin_index].each_index do |answer_index|
				scaled_color = @bins[bin_index][answer_index]/1.0
				fill(0.5,1,scaled_color) if @bins[bin_index][answer_index] > 0
				fill(1.0,1,0) if @bins[bin_index][answer_index] == 0
				point = {:x => answer_index, :y => bin_index}
				@screen.plot(point, @basis) {|point| rect(point[:x],point[:y],@scale,@scale)}
			end
		end
		@screen.draw_axes(@basis,10,10)
	end

	def draw
		stroke(0,0,0)
		@old_rectangles.each do |old|
			scaled_color = @bins[old[:y]][old[:x]]
			fill(0.5,1,scaled_color)
			@screen.plot(old, @basis) {|p| rect(p[:x],p[:y],@scale,@scale)}
		end
		@rectangles_to_highlight.each do |new_rectangle|
			fill(0.1,1,1)
			@screen.plot(new_rectangle, @basis) {|p| rect(p[:x],p[:y],@scale,@scale)}
		end
		@old_rectangles = @rectangles_to_highlight
		@screen.draw_axes(@basis,10,10)
	end

	def mouseMoved
		original_point = @screen.original({:x => mouseX, :y => mouseY}, @basis)
		original_point = {:x => original_point[:x].round, :y => original_point[:y].round}
		return if original_point[:x] > 55 || original_point[:y] > 55 || original_point[:x] < 0 || original_point[:y] < 0
		@rectangles_to_highlight = [{:x => original_point[:x].round, :y => original_point[:y].round}]
		redraw
	end

end

h = 1000
w = 1400
MySketch.new(:title => "My Sketch", :width => w, :height => h)

