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
				   end

		@screen_height = 900
		@width = width
		@height = height
		@screen_transform = Transform.new({:x => 10.0, :y => -7500.0}, {:x => 600.0, :y => @screen_height})
		no_loop
		smooth
		background(0,0,0)

		responses = Response.find(:all)
		predictor_metric = ->(r) {r[:pre_total]}
		predicted_metric = ->(r) {r[:language]}
		
		responses.each do |r|
			bin = predicted_metric.call(r)
			bins[bin] = [] if bins[bin].nil?
			bins[bin] << r
		end


		kde = KernelDensityEstimator.new(bins, predictor_metric)
		overall_density = BucketwiseDensity.new(responses, predictor_metric)

		x_range = {:minimum => -60, :maximum => 60}
		y_range = {:minimum => 0, :maximum => 1}
		@c = CoordinateSystem.standard(x_range, y_range, self)
		@screen = Screen.new(@screen_transform, self, @c)

		stroke(0.3,1,1,0.4)
		fill(0.3,1,1,0.4)
		@screen.join = true
		
		rect_mode(CENTER)
		kde.each_distribution do |bucket,d|
			x = 0
			while x <= 57
				@screen.plot({:x => x, :y => d.estimate(x)})
				x += 1
			end
		end
		bins.keys.sort.each do|k|
			v = estimate(kernels, k, responses.count)
			@screen.plot({:x => k, :y => v}, :track => true)
		end
		@screen.join = false
		stroke(0.9,0.0,1)
		fill(0.9,0.0,1)
		@screen.draw_axes(5,0.01)
	end
	
	def draw
	end
end

class KernelDensityEstimator
	def initialize(responses, predictor_metric, predicted_metric_buckets)
		@distributions = {}
		predicted_metric_buckets.each_pair do |predicted_metric_value, responses|
			bucketed_density = BucketwiseDensity.new(responses, predictor_metric)
			@distributions[predicted_metric_value] = bucketed_density
		end
	end
	
	def each_distribution(&block)
		@distributions.each_pair |k,v|
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
			sum += v[:kernel].call(key) * v[:n]
		end
		sum / n
	end

end

w = 1200
h = 1000

MySketch.send :include, Interactive
MySketch.new(:title => "Kernel Density Estimation", :width => w, :height => h)

