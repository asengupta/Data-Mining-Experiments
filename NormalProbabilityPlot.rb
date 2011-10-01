require 'rubygems'
Gem.clear_paths
ENV['GEM_HOME'] = '/home/avishek/jruby/jruby-1.6.3/lib/ruby/gems/1.8'
ENV['GEM_PATH'] = '/home/avishek/jruby/jruby-1.6.3/lib/ruby/gems/1.8'

require 'schema'
require 'basis_processing'

class MySketch < Processing::App
	app = self
	
	def setup
		@screen_height = 900
		@width = width
		@height = height
		@screen_transform = Transform.new({:x => 10.0, :y => -5.0}, {:x => 600.0, :y => @screen_height})
		@screen = Screen.new(@screen_transform, self)
		frame_rate(30)
		smooth
		background(0,0,0)
		color_mode(RGB, 1.0)

		responses = Response.find(:all)
#		p responses.select {|r| r[:pre_total] == 0 && r[:post_total] > 50}
#		exit

		improvement_bins = {}
		responses.each do |r|
			improvement = r[:post_total] - r[:pre_total]
			improvement_bins[improvement] = responses.select {|r| r[:post_total] - r[:pre_total] <= improvement}.count/responses.count.to_f * 100.0 if improvement_bins[improvement] == nil
		end

		least_improvement = improvement_bins.keys.min
		most_improvement = improvement_bins.keys.max

		@x_unit_vector = {:x => 1.0, :y => 0.0}
		@y_unit_vector = {:x => 0.0, :y => 1.0}

		x_range = ContinuousRange.new({:minimum => least_improvement, :maximum => most_improvement})
		y_range = ContinuousRange.new({:minimum => 0.0, :maximum => 100.0})

		@c = CoordinateSystem.new(Axis.new(@x_unit_vector,x_range), Axis.new(@y_unit_vector,y_range), [[1,0],[0,1]], self)
		@screen.draw_axes(@c,5,5)
		stroke(1,1,0,1)
		fill(1,1,0)
		improvement_bins.each_pair do |improvement,percentage|
			@screen.plot({:x => improvement, :y => percentage}, @c)
		end
	end

	def draw
	end
end

w = 1200
h = 1000

MySketch.new(:title => "My Sketch", :width => w, :height => h)


