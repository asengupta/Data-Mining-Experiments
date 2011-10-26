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
		@screen_transform = Transform.new({:x => 10.0, :y => -3000.0}, {:x => 600.0, :y => @screen_height})
		no_loop
		smooth
		background(0,0,0)

		responses = Response.find(:all)
		predictor_metric = ->(r) {r.improvement}
		predicted_metric = ->(r) {r[:language]}
		
		bins = {}
		priors = {}
		responses.each do |r|
			bin = predicted_metric.call(r)
			bins[bin] = [] if bins[bin].nil?
			bins[bin] << r
			priors[bin] = 0 if priors[bin].nil?
			priors[bin] += 1
		end

		priors.each_pair do |k,v|
			priors[k] = v/responses.count.to_f
		end
		
		kde = KernelDensityEstimator.new(predictor_metric, bins, responses)

		x_range = {:minimum => -60, :maximum => 60}
		y_range = {:minimum => 0, :maximum => 1}
		@c = CoordinateSystem.standard(x_range, y_range, self)
		@screen = Screen.new(@screen_transform, self, @c, LegendBox.new(self, {:x => 1300, :y => 30}))

		classifier = Classifier.new(kde, priors)
		hue = 0.0
		rect_mode(CENTER)
		priors.each_key do |k|
			x = -60
			points = []
			stroke(hue,1,1)
			fill(hue,1,1)
			@screen.join = true
			while x <= 57
				points << {:x => x, :y => classifier.probability(:category => k, :given => x)[:probability]}
				x += 0.1
			end
			@screen.plot(points, :legend => k){|o,m,s|}
			@screen.join = false
			hue += 0.05
		end
#		hue = 0.0
#		rect_mode(CENTER)
#		kde.each_distribution do |bucket,d|
#			x = -60
#			stroke(hue,1,1)
#			fill(hue,1,1)
#			@screen.join = true
#			while x <= 57
#				@screen.plot({:x => x, :y => d.estimate(x)}){|o,m,s|}
#				x += 0.1
#			end
#			@screen.join = false
#			hue += 0.1
#		end

#		@screen.join = true
#		0..57.times {|x| @screen.plot({:x => x, :y => kde.overall_density.estimate(x)}){|o,m,s|}}
		stroke(0.9,0.0,1)
		fill(0.9,0.0,1)
		@screen.draw_axes(5,0.01)
	end
	
	def draw
	end
end

class Classifier
	def initialize(estimator, priors)
		@estimator = estimator
		@priors = priors
	end
	
	def probability(posterior_question)
		y = posterior_question[:category]
		x = posterior_question[:given]
		probability_of_posterior = @estimator[y].estimate(x) * @priors[y] / @estimator.overall_density.estimate(x)
		{ :probability_of => y, :given => x, :probability => probability_of_posterior}
	end
end


class KernelDensityEstimator
	attr_accessor :overall_density
	def initialize(predictor_metric, predicted_metric_buckets, all_responses)
		@distributions = {}
		predicted_metric_buckets.each_pair do |predicted_metric_value, responses|
			bucketed_density = BucketwiseDensity.new(responses, predictor_metric)
			@distributions[predicted_metric_value] = bucketed_density
		end
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

#MySketch.send :include, Interactive
MySketch.new(:title => "Kernel Density Estimation", :width => w, :height => h)

