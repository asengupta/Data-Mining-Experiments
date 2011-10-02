require 'rubygems'
Gem.clear_paths
ENV['GEM_HOME'] = '/home/avishek/jruby/jruby-1.6.3/lib/ruby/gems/1.8'
ENV['GEM_PATH'] = '/home/avishek/jruby/jruby-1.6.3/lib/ruby/gems/1.8'

require 'schema'
require 'basis_processing'
require 'quantiles'

class MySketch < Processing::App
	app = self
	
	def setup
		@screen_height = 900
		@width = width
		@height = height
		@screen_transform = Transform.new({:x => 5.0, :y => -5.0}, {:x => 600.0, :y => @screen_height / 2})
		@screen = Screen.new(@screen_transform, self)
		frame_rate(30)
		smooth
		background(0,0,0)
		color_mode(RGB, 1.0)

		responses = Response.find(:all)
		improvement_bins = {}
		data_bins = {}
		normal_bins = {}
		responses.each do |r|
			improvement_bins[r.improvement] = responses.select {|rsp| rsp.improvement <= r.improvement}.count/responses.count.to_f * 100.0 if improvement_bins[r.improvement] == nil
		end
		
		quantile_fn = Quantiles.quantile_normal(4, 260)
		improvement_bins.each_pair do |improvement, percentage|
			normal_bins[percentage] = quantile_fn.call(percentage/100.0)
			data_bins[percentage] = improvement
		end
		least_improvement = improvement_bins.keys.min
		most_improvement = improvement_bins.keys.max

		@x_unit_vector = {:x => 1.0, :y => 0.0}
		@y_unit_vector = {:x => 0.0, :y => 1.0}

		x_range = ContinuousRange.new({:minimum => least_improvement, :maximum => most_improvement})
		y_range = ContinuousRange.new({:minimum => least_improvement, :maximum => most_improvement})

		@c = CoordinateSystem.new(Axis.new(@x_unit_vector,x_range), Axis.new(@y_unit_vector,y_range), [[1,0],[0,1]], self)
		@screen.draw_axes(@c,10,10)
		rect_mode(CENTER)
		normal_bins.each_key do |p|
			stroke(1,1,0,1)
			fill(1,1,0)
			@screen.plot({:x => normal_bins[p], :y => data_bins[p]}, @c)
			stroke(0,1,0,1)
			no_fill()
			@screen.plot({:x => normal_bins[p], :y => normal_bins[p]}, @c) { |p| rect(p[:x], p[:y], 4, 4)}
		end
	end

	def draw
	end
end

w = 1200
h = 1000

MySketch.new(:title => "Normal Probability Plot", :width => w, :height => h)


