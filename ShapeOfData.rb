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
		@highlight_block = ->(o,m,s) do
			rect_mode(CENTER)
			rect(m[:x], m[:y], 8, 8)
			text("(#{o[:x]}, #{o[:y]}) -> #{o[:value]}", m[:x] + 5, m[:y] + 5)
		end
		@screen_height = 900
		@width = width
		@height = height
#		@screen_transform = Transform.new({:x => 18.0, :y => -7500.0}, {:x => 100.0, :y => @screen_height})
		@screen_transform = Transform.new({:x => 10.0, :y => -7500.0}, {:x => 500, :y => @screen_height})
		smooth
		no_loop
		background(0,0,0)
		color_mode(HSB, 1.0)

		responses = Response.find(:all)

		@c = CoordinateSystem.standard({:minimum => -60, :maximum => 60}, {:minimum => 0.0, :maximum => 0.12}, self, {:x => 'Score', :y => 'Probability'})
		@screen = Screen.new(@screen_transform, self, @c)

#		stroke(0.1,0.5,1)
#		fill(0.1,0.5,1)
#		plot_distribution(responses, ->(r) {r.improvement}, "Improvement")
#		stroke(0.2,0.5,1)
#		fill(0.2,0.5,1)
#		plot_distribution(responses, ->(r) {r[:pre_total]}, "Pre-Total")
		stroke(0.4,0.5,1)
		fill(0.4,0.5,1)
		plot_distribution(responses, ->(r) {r[:post_total]}, "Post-Total")
		stroke(0.1,0.5,1)
		fill(0.1,0.5,1)
		plot_theoretical{|x| 0.106 * Math.exp(-0.106*(56-x))}
#		plot_theoretical{|x| 0.04 * Math.exp(-0.04*(56-x))}
#		transform = box_cox(0.5)
#		stroke(0.2,0.5,1)
#		fill(0.2,0.5,1)
#		plot_distribution(responses.select {|r| r[:pre_total] <= 20}, ->(r) {r.improvement})
#		stroke(0.4,0.5,1)
#		fill(0.4,0.5,1)
#		plot_distribution(responses.select {|r| r[:pre_total] <= 30 && r[:pre_total] > 20}, ->(r) {r.improvement})
#		stroke(0.6,0.5,1)
#		fill(0.6,0.5,1)
#		plot_distribution(responses.select {|r| r[:pre_total] <= 45 && r[:pre_total] > 30}, ->(r) {r.improvement})
#		stroke(0.8,0.5,1)
#		fill(0.8,0.5,1)
#		plot_distribution(responses.select {|r| r[:pre_total] > 45}, ->(r) {r.improvement})

		color_mode(RGB, 1.0)
#		stroke(1,1,0,1)
#		fill(1,1,0)
#		plot_distribution(responses, ->(r) {1.0 / Math.sqrt(r[:pre_total])})
#		stroke(0,1,0,1)
#		fill(0,1,0)
#		plot_distribution(responses, ->(r) {1.0 / Math.sqrt(r[:post_total])})
		@screen.draw_axes(5, 0.01)

#		value_sum = 0
#		responses.each do |r|
#			value_sum += improvement_metric.call(r)
#		end
#		mean = value_sum.to_f/responses.count
#		sum_of_squares = 0
#		responses.each do |r|
#			sum_of_squares += (improvement_metric.call(r) - mean)**2
#		end
#		variance = sum_of_squares.to_f/responses.count
#		fitted_curve = Distributions.normal(mean, 0.028)
#		fitted_curve = Distributions.cauchy(mean - 0.01, 0.14)
#		p "Variance=#{variance}, Mean = #{mean}"
#		stroke(1,0.5,1)
#		fill(1,0.5,1)

#		sum = 0.0
#		improvement_bins.values.each do |v|
#			sum += v
#		end
#		improvement_bins.each_pair do|k,v|
#			@screen.plot({:x => k, :y => fitted_curve.call(k)/60.0}, :bar => true)
#		end
#		stroke(0.2,1,1)
#		fill(0.2,1,1)
#		@screen.join = false
#		@screen.join = true
#		improvement_bins.keys.sort.each do|k|
#			@screen.plot({:x => k, :y => improvement_bins[k]}, :track => true)
#		end
	end

	def plot_theoretical(&p)
		@screen.join=true
		0.upto(56) do |x|
			point = {:x => x, :y => p.call(x)}
			@screen.plot(point) {|o,m,s|}
		end
		@screen.join=false
	end

	def box_cox(l)
		->(x) {(x**l - 1)/l}
	end
	
	def plot_distribution(responses, metric, legend)
		improvement_bins = {}
		responses.each do |r|
			improvement = metric.call(r)
			improvement_bins[improvement] = improvement_bins[improvement] == nil ? 1 : improvement_bins[improvement] + 1
		end
		
		improvement_bins.each_pair do |k, v|
			improvement_bins[k] = v / responses.count.to_f
		end

		least_improvement = improvement_bins.keys.min
		most_improvement = improvement_bins.keys.max

		points = []
		improvement_bins.keys.sort.each do|k|
			points << {:x => k, :y => improvement_bins[k]}
		end
		@screen.join = true
		@screen.plot(points, :track => true, :legend => legend)
		@screen.join = false
	end
	
	def draw
	end
end

w = 1200
h = 1000

MySketch.send :include, Interactive
MySketch.new(:title => "Shape of Score Data", :width => w, :height => h)


