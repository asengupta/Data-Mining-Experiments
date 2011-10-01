require 'rubygems'
Gem.clear_paths
ENV['GEM_HOME'] = '/home/avishek/jruby/jruby-1.6.3/lib/ruby/gems/1.8'
ENV['GEM_PATH'] = '/home/avishek/jruby/jruby-1.6.3/lib/ruby/gems/1.8'

require 'schema'
require 'basis_processing'

class MySketch < Processing::App
	app = self

	def normal(mean, variance)
		lambda {|x| 1.0/(Math.sqrt(2.0 * Math::PI * variance)) * Math.exp(-((x - mean)**2) / (2 * variance))}
	end

	def setup
		@screen_height = 900
		@width = width
		@height = height
		@screen_transform = Transform.new({:x => 10.0, :y => -15000.0}, {:x => 500.0, :y => @screen_height})
		@screen = Screen.new(@screen_transform, self)
		frame_rate(30)
		smooth
		background(0,0,0)
		color_mode(RGB, 1.0)

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
			improvement = r[:post_total] - r[:pre_total]
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
		@screen.draw_axes(@c,5,0.1)
		stroke(1,1,0,1)
		fill(1,1,0)
#		pre_bins.each_index do |position|
#			@screen.plot({:x => position, :y => pre_bins[position]}, @c)
#		end

		stroke(0,1,0,1)
		fill(0,1,0)
#		post_bins.each_index do |position|
#			@screen.plot({:x => position, :y => post_bins[position]}, @c)
#		end

		value_sum = 0
		responses.each do |r|
			value_sum += r[:post_total] - r[:pre_total]
		end
		mean = value_sum.to_f/responses.count
		mean = 5.0
		sum_of_squares = 0
		responses.each do |r|
			sum_of_squares += (r[:post_total] - r[:pre_total] - mean)**2
		end
		variance = sum_of_squares.to_f/responses.count
		variance = 260.0
		fitted_curve = normal(mean, variance)
		p "Variance=#{variance}, Mean = #{mean}"
		stroke(0,1,0,1)
		fill(0.7,1,0)
		improvement_bins.each_pair do|k,v|
			@screen.plot({:x => k, :y => fitted_curve.call(k)}, @c, :bar => true)
		end
		stroke(1,1,0,1)
		fill(1,0.5,0)
		improvement_bins.each_pair do|k,v|
			@screen.plot({:x => k, :y => v}, @c)
		end
	end

	def draw
	end
end

w = 1200
h = 1000

MySketch.new(:title => "My Sketch", :width => w, :height => h)


