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
		@screen_transform = Transform.new({:x => 1.0, :y => -300.0}, {:x => 500.0, :y => @screen_height/2})
		@screen = Screen.new(@screen_transform, self)
		frame_rate(30)
		smooth
		background(0,0,0)
		color_mode(RGB, 1.0)

		handle = File.open('/home/avishek/Code/DataMiningExperiments/data.txt', 'r')
		inputs = []

		responses = []
		samples = 0
		handle.each_line do |l|
#			break if samples > 20
			responses << l.to_f
#			samples += 1
		end

		@x_unit_vector = {:x => 1.0, :y => 0.0}
		@y_unit_vector = {:x => 0.0, :y => 1.0}

		x_range = ContinuousRange.new({:minimum => 0, :maximum => 0})
		y_range = ContinuousRange.new({:minimum => -1.0, :maximum => 1.0})

		@c = CoordinateSystem.new(Axis.new(@x_unit_vector,x_range), Axis.new(@y_unit_vector,y_range), [[10,0],[0,1]], self)
		@screen.draw_axes(@c,10,0.1)
		stroke(1,1,0,1)
		no_fill()
#		fill(1,1,0)
		responses.each do |r|
			@screen.plot({:x => 20, :y => r}, @c) {|p| point(p[:x],p[:y])}
		end
	end

	def draw
	end
end

w = 1200
h = 1000

MySketch.new(:title => "My Sketch", :width => w, :height => h)

