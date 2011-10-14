require 'rubygems'
Gem.clear_paths
ENV['GEM_HOME'] = '/home/avishek/jruby/jruby-1.6.4/lib/ruby/gems/1.8'
ENV['GEM_PATH'] = '/home/avishek/jruby/jruby-1.6.4/lib/ruby/gems/1.8'

require 'schema'
require 'basis_processing'
require 'quantiles'
require 'distributions'

class MySketch < Processing::App
	app = self
	
	def setup
		@highlight_block = lambda do |o,m,s|
					rect_mode(CENTER)
					stroke(1,0,0)
					fill(1,0,0)
					rect(m[:x], m[:y], 5, 5)
				   end

		metric = lambda {|r| Math.log(r.improvement + 58)}
		@screen_height = 700
		@width = width
		@height = height
		no_loop
		smooth
		background(0,0,0)
		color_mode(RGB, 1.0)

		responses = Response.find(:all)
		cumulative_improvement_bins = {}
		data_bins = {}
		normal_bins = {}
		responses.each do |r|
			cumulative_improvement_bins[metric.call(r)] = responses.select {|rsp| metric.call(rsp) <= metric.call(r)}.count/responses.count.to_f * 100.0 if cumulative_improvement_bins[metric.call(r)] == nil
		end
		
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

		quantile_fn = Quantiles.quantile_cauchy(mean - 0.01, 0.14)
		cumulative_improvement_bins.each_pair do |improvement, percentage|
			normal_bins[percentage] = quantile_fn.call(percentage/100.0)
			data_bins[percentage] = improvement
		end
		least_improvement = cumulative_improvement_bins.keys.min
		most_improvement = cumulative_improvement_bins.keys.max

		@screen_transform = Transform.new({:x => 8.0, :y => -8.0}, {:x => @width / 2, :y => 500})
		x_range = {:minimum => least_improvement, :maximum => most_improvement}
		y_range = {:minimum => least_improvement, :maximum => most_improvement}
		@c = CoordinateSystem.standard(x_range, y_range, self)
		@screen = Screen.new(@screen_transform, self, @c)
		@screen.join = true

		rect_mode(CENTER)
		keys = normal_bins.keys.sort
#		no_fill()
		stroke(1,1,0,1)
		keys.each do |p|
			@screen.plot({:x => normal_bins[p], :y => data_bins[p]}, :track => true)
		end
		@screen.join=false
		@screen.join=true
		stroke(0,1,0,1)
		keys.each do |p|
			@screen.plot({:x => normal_bins[p], :y => normal_bins[p]}, :track => true) { |o,m,s| rect(m[:x], m[:y], 4, 4)}
		end
		stroke(1,1,1,1)
		@screen.draw_axes(10,10)
	end

	def draw
	end
end

w = 1400
h = 900

MySketch.send :include, Interactive
MySketch.new(:title => "Normal Probability Plot", :width => w, :height => h)


