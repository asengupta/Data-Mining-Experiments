require 'rubygems'
Gem.clear_paths
ENV['GEM_HOME'] = '/home/avishek/jruby/jruby-1.6.4/lib/ruby/gems/1.8'
ENV['GEM_PATH'] = '/home/avishek/jruby/jruby-1.6.4/lib/ruby/gems/1.8'

require 'schema'
require 'basis_processing'

class MySketch < Processing::App
	app = self
	def setup
		@screen_height = 900
		@width = width
		@height = height
		@screen_transform = Transform.new({:x => 10.0, :y => -0.5}, {:x => 500.0, :y => @screen_height})

		@c = CoordinateSystem.standard({:minimum => -5.0, :maximum => 5.0}, {:minimum => 0.0, :maximum => 2000.0}, self)
		@screen = Screen.new(@screen_transform, self, @c)
		frame_rate(30)
		smooth
		background(0,0,0)
		color_mode(RGB, 1.0)

		post_bins = bins_for('/home/avishek/Code/DataMiningExperiments/data-post.txt')
		pre_bins = bins_for('/home/avishek/Code/DataMiningExperiments/data-pre.txt')


		stroke(1,1,0,1)
#		no_fill()
		fill(1,1,0)
#		pre_bins.each do |r|
#			@screen.plot({:x => r[:from], :y => r[:value]})
#		end
		stroke(0,1,0,1)
		fill(0,1,0)
		post_bins.each do |r|
			@screen.plot({:x => r[:from], :y => r[:value]}, :bar => true)
		end
		@screen.draw_axes(0.5,100)
	end

	def draw
	end

	def bins_for(filename)
		handle = File.open(filename, 'r')
		inputs = []

		responses = []
		samples = 0
		handle.each_line do |l|
#			break if samples > 20
			responses << l.to_f
#			samples += 1
		end

		bins = []

		interval = (responses.max - responses.min)/100.0
		current = responses.min
		while (current <= responses.max)
			bin_value = responses.select {|r| r >= current && r < current + interval}.count
			bins << {:from => current, :to => current + interval, :value => bin_value}
			current += interval
		end
		bins
	end
end

w = 1200
h = 1000

MySketch.new(:title => "ReducedDimensionDistribution", :width => w, :height => h)

