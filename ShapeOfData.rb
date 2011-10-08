require 'rubygems'
Gem.clear_paths
ENV['GEM_HOME'] = '/home/avishek/jruby/jruby-1.6.4/lib/ruby/gems/1.8'
ENV['GEM_PATH'] = '/home/avishek/jruby/jruby-1.6.4/lib/ruby/gems/1.8'

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

		x_range = ContinuousRange.new({:minimum => least_improvement, :maximum => most_improvement})
		y_range = ContinuousRange.new({:minimum => 0.0, :maximum => 1.0})
		@c = CoordinateSystem.standard(x_range, y_range, self)
		@screen = Screen.new(@screen_transform, self, @c)

		@screen.draw_axes(5,0.01)
		stroke(1,1,0,1)
		fill(1,1,0)
#		pre_bins.each_index do |position|
#			@screen.plot({:x => position, :y => pre_bins[position]})
#		end

		stroke(0,1,0,1)
		fill(0,1,0)
#		post_bins.each_index do |position|
#			@screen.plot({:x => position, :y => post_bins[position]})
#		end

		value_sum = 0
		responses.each do |r|
			value_sum += r.improvement
		end
		mean = value_sum.to_f/responses.count
		sum_of_squares = 0
		responses.each do |r|
			sum_of_squares += (r.improvement - mean)**2
		end
		variance = sum_of_squares.to_f/responses.count
		fitted_curve = Distributions.normal(mean, variance)
#		fitted_curve = cauchy(mean, 5)
		p "Variance=#{variance}, Mean = #{mean}"
		stroke(1,0.5,1)
		fill(1,0.5,1)

		sum = 0.0
		improvement_bins.values.each do |v|
			sum += v
		end
		improvement_bins.each_pair do|k,v|
			@screen.plot({:x => k, :y => fitted_curve.call(k)}, :bar => true)
		end
		stroke(0.2,1,1)
		fill(0.2,1,1)
		improvement_bins.each_pair do|k,v|
			@screen.plot({:x => k, :y => v})
		end
	end

	def draw
	end
end

w = 1200
h = 1000

MySketch.new(:title => "My Sketch", :width => w, :height => h)


