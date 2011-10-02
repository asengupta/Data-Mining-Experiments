require 'rubygems'
Gem.clear_paths
ENV['GEM_HOME'] = '/home/avishek/jruby/jruby-1.6.3/lib/ruby/gems/1.8'
ENV['GEM_PATH'] = '/home/avishek/jruby/jruby-1.6.3/lib/ruby/gems/1.8'

require 'schema'
require 'basis_processing'
require 'quantiles'
require 'distributions'

class MySketch < Processing::App
	app = self
	
	def setup
		metric = lambda {|r| r.improvement}
		@screen_height = 900
		@width = width
		@height = height
		@screen_transform = Transform.new({:x => 5.0, :y => -5.0}, {:x => 1200.0, :y => @screen_height / 2})
		@screen = Screen.new(@screen_transform, self)
		frame_rate(30)
		smooth
		background(0,0,0)
		color_mode(RGB, 1.0)

		responses = Response.find(:all)
		cumulative_improvement_bins = {}
		improvement_bins = {}
		data_bins = {}
		normal_bins = {}
		responses.each do |r|
			cumulative_improvement_bins[metric.call(r)] = responses.select {|rsp| metric.call(rsp) <= metric.call(r)}.count/responses.count.to_f * 100.0 if cumulative_improvement_bins[metric.call(r)] == nil
			improvement_bins[metric.call(r)] = improvement_bins[metric.call(r)] == nil ? 1 : improvement_bins[metric.call(r)] + 1
		end
		improvement_bins = improvement_bins.each_pair {|k,v| improvement_bins[k] = v/responses.count.to_f * 100.0}
		
		value_sum = 0
		responses.each do |r|
			value_sum += metric.call(r)
		end
		mean = value_sum.to_f/responses.count
		sum_of_squares = 0
		responses.each do |r|
			sum_of_squares += (metric.call(r) - mean)**2
		end
		variance = sum_of_squares.to_f/responses.count

		quantile_fn = Quantiles.quantile_normal(mean, variance)
		cumulative_improvement_bins.each_pair do |improvement, percentage|
			normal_bins[percentage] = quantile_fn.call(percentage/100.0)
			data_bins[percentage] = improvement
		end
		least_improvement = cumulative_improvement_bins.keys.min
		most_improvement = cumulative_improvement_bins.keys.max

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
		normal_distribution = Distributions.normal(mean, variance)
		residual_hash = {}
		improvement_bins.each_key do |improvement|
			residual = - normal_distribution.call(improvement) * 100.0 + cumulative_improvement_bins[improvement]
#			p "#{normal_distribution.call(improvement) * 100.0} == #{cumulative_improvement_bins[improvement]}"
			residual_hash[improvement] = residual
		end
		p "Minimum = #{residual_hash.values.min}"
		p "Maximum = #{residual_hash.values.max}"
		x_range = ContinuousRange.new({:minimum => residual_hash.keys.min, :maximum => residual_hash.keys.max})
		y_range = ContinuousRange.new({:minimum => residual_hash.values.min, :maximum => residual_hash.values.max})
		@c = CoordinateSystem.new(Axis.new(@x_unit_vector,x_range), Axis.new(@y_unit_vector,y_range), [[1,0],[0,1]], self)
		@residual_screen_transform = Transform.new({:x => 5.0, :y => -5.0}, {:x => 300.0, :y => @screen_height})
		@residuals_screen = Screen.new(@residual_screen_transform, self)

		improvement_bins.each_pair do |improvement, residual|
			@residuals_screen.plot({:x => improvement, :y => residual}, @c)
		end
		@residuals_screen.draw_axes(@c, 10, 2.0)
	end

	def draw
	end
end

w = 2000
h = 1000

MySketch.new(:title => "Normal Probability Plot", :width => w, :height => h)


