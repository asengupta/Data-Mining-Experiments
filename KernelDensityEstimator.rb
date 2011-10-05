require 'rubygems'
Gem.clear_paths
ENV['GEM_HOME'] = '/home/avishek/jruby/jruby-1.6.3/lib/ruby/gems/1.8'
ENV['GEM_PATH'] = '/home/avishek/jruby/jruby-1.6.3/lib/ruby/gems/1.8'

require 'schema'
require 'basis_processing'
require 'distributions'

class MySketch < Processing::App
	app = self
	
	def setup
		@screen_height = 900
		@width = width
		@height = height
		@screen_transform = Transform.new({:x => 10.0, :y => -15000.0}, {:x => 500.0, :y => @screen_height})
		@screen = Screen.new(@screen_transform, self)
		frame_rate(30)
		smooth
		background(0,0,0)
		color_mode(HSB, 1.0)

		responses = Response.find(:all)

		pre_bins = []
		post_bins = []
		improvement_bins = {}

		57.times {pre_bins << 0}
		57.times {post_bins << 0}

		57.times do |pre_score|
			pre_bins[pre_score] = responses.select {|r| r.pre_total == pre_score}.count
		end
		57.times do |post_score|
			post_bins[post_score] = responses.select {|r| r.post_total == post_score}.count
		end

		responses.each do |r|
			improvement = r.improvement
			improvement_bins[improvement] = improvement_bins[improvement] == nil ? 1 : improvement_bins[improvement] + 1
		end

		improvement_bins.each_pair do |k, v|
			improvement_bins[k] = v / responses.count.to_f
		end

		least_improvement = improvement_bins.keys.min
		most_improvement = improvement_bins.keys.max

		@x_unit_vector = {:x => 1.0, :y => 0.0}
		@y_unit_vector = {:x => 0.0, :y => 1.0}

		x_range = ContinuousRange.new({:minimum => least_improvement, :maximum => most_improvement})
		y_range = ContinuousRange.new({:minimum => 0.0, :maximum => 1.0})

		@c = CoordinateSystem.new(Axis.new(@x_unit_vector,x_range), Axis.new(@y_unit_vector,y_range), [[1,0],[0,1]], self)
		@screen.draw_axes(@c,5,0.01)
		stroke(0.2,1,1)
		fill(0.2,1,1)
		improvement_bins.each_pair do|k,v|
			@screen.plot({:x => k, :y => v}, @c)
		end
		
		kernels = {}
		improvement_bins.each_pair do |k,v|
			kernels[k] = {:kernel => Distributions.normal(k, 0.5), :n => v * responses.count}
		end
		stroke(0.6,1,1)
		fill(0.6,1,1)
		@screen.join = true
		improvement_bins.keys.sort.each do|k|
			v = estimate(kernels, k, responses.count)
			@screen.plot({:x => k, :y => v}, @c)
		end
		@screen.join = false
		rect_mode(CENTER)
		stroke(0.9,1,1)
		fill(0.9,1,1)
		kernels.each_value do |v|
			x = least_improvement.to_f
			while (x < most_improvement)
				@screen.join = true
				@screen.plot({:x => x, :y => v[:kernel].call(x) * v[:n] / responses.count}, @c) {|p| point(p[:x], p[:y])}
				x += 0.1
			end
			@screen.join = false
		end
	end
	
	def estimate(kernels, key, n)
		sum = 0.0
		kernels.each_pair do |k,v|
			sum += v[:kernel].call(key) * v[:n]
		end
		sum / n
	end

	def draw
	end
end

w = 1200
h = 1000

MySketch.new(:title => "Kernel Density Estimation", :width => w, :height => h)


