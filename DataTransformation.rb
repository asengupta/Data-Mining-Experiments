require 'schema'
require 'basis_processing'
require 'distributions'

class MySketch < Processing::App
	app = self
	def setup
		color_mode(HSB, 1.0)
		@highlight_block = lambda do |o,m,s|
					rect_mode(CENTER)
					stroke(0.3,1,1)
					fill(0.3,1,1)
					rect(m[:x], m[:y], 5, 5)
					text(o[:category].strip == '' ? '[Unknown]' : o[:category], m[:x], m[:y] - 15)
				   end

		@screen_height = 900
		@width = width
		@height = height
		@screen_transform = Transform.new({:x => 50.0, :y => -10000.0}, {:x => 600.0, :y => @screen_height})
		no_loop
		smooth
		background(0,0,0)

		responses = Response.find(:all)
		predictor_metric = ->(r) {57 + r.improvement}
		
		kde = KernelDensityEstimator.new(predictor_metric, responses)

		x_range = {:minimum => -60, :maximum => 60}
		y_range = {:minimum => 0, :maximum => 1}
		@c = CoordinateSystem.standard(x_range, y_range, self, {:x => 'Score', :y => 'Probability P(score)'})
		@screen = Screen.new(@screen_transform, self, @c, LegendBox.new(self, {:x => 1300, :y => 30}))

		rect_mode(CENTER)
		points = []
		x = 0.0
		fill(0.3,1,1)
		while x <= 56.0
			y = kde.overall_density.estimate(x)
			points << {:x => x, :y => y}
			x += 0.1
		end
		b = box_cox(0.12)
		transformed_points = points.collect {|p| { :x => b.call(p[:x]), :y => p[:y]}}
		transformed_responses = []
		transformed_points.each do |p|
			(p[:y]*responses.count).to_i.times do |i|
				transformed_responses << p[:x]
			end
		end
		fill(0.3,1,1)
		stroke(0.3,1,1)
		@screen.join=true
		@screen.plot(points){|o,m,s|}
		fill(0.5,1,1)
		stroke(0.5,1,1)
		@screen.join=false
		@screen.join=true
		@screen.plot(transformed_points) {|o,m,s|}
		puts jb_stats(transformed_responses)

		stroke(0.9,0.0,1)
		fill(0.9,0.0,1)
		@screen.draw_axes(5,0.005)
	end
	
	def box_cox(l)
		lambda {|x|(Math.exp(x*l) - 1)/l}
	end

	def draw
	end

	def jb_stats(responses)
		n = responses.count.to_f
		mean = 0.0
		responses.each {|r| mean += r}
		mean /= responses.count

		mu4 = mu(responses, mean, 4)
		mu3 = mu(responses, mean, 3)
		variance = mu(responses, mean, 2)
		alpha3 = Math.sqrt(variance)**3
		alpha4 = variance**2

		s = mu3.to_f/alpha3
		k = mu4.to_f/alpha4

		jb = n/6 * (s**2 + 0.25 * (k-3)**2)
		puts "JB statistic = #{jb}"
#		puts "Variance = #{variance}"
#		puts "Skew = #{s}"
		s
#		puts "n = #{n}"
#		puts "Skewness = #{s}"
#		puts "Kurtosis = #{k}"
#		puts "JB statistic = #{jb}"
	end
	
	def mu(samples, mean, order)
		sum = 0.0
		samples.each {|s| sum += (s - mean)**order}
		sum/samples.count
	end
end

class KernelDensityEstimator
	attr_accessor :overall_density
	def initialize(predictor_metric, all_responses)
		@overall_density = BucketwiseDensity.new(all_responses, predictor_metric)
	end
	
	def [](key)
		@distributions[key]
	end
	
	def each_distribution(&block)
		@distributions.each_pair do |k,v|
			yield(k,v)
		end
	end
end

class BucketwiseDensity
	def initialize(responses, predictor_metric)
		bins = {}
		@count = responses.count
		responses.each do |r|
			bin = predictor_metric.call(r)
			bins[bin] = bins[bin] == nil ? 1 : bins[bin] + 1
		end

		bins.each_pair do |k, v|
			bins[k] = v / responses.count.to_f
		end
		@kernels = {}
		bins.each_pair do |k,v|
			@kernels[k] = {:kernel => Distributions.normal(k, 3.0), :n => v * responses.count}
		end
	end
	
	def estimate(x)
		sum = 0.0
		@kernels.each_value do |v|
			sum += v[:kernel].call(x) * v[:n]
		end
		sum / @count
	end

end

w = 1500
h = 1000

MySketch.send :include, Interactive
MySketch.new(:title => "Kernel Density Estimation", :width => w, :height => h)

