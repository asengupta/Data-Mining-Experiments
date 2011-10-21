require 'rubygems'
Gem.clear_paths
ENV['GEM_HOME'] = '/home/avishek/jruby/jruby-1.6.4/lib/ruby/gems/1.8'
ENV['GEM_PATH'] = '/home/avishek/jruby/jruby-1.6.4/lib/ruby/gems/1.8'

require 'schema'
require 'basis_processing'
require 'distributions'

class MySketch < Processing::App
	app = self
	
	def mean(responses, &metric)
		mean = 0.0
		responses.each {|r| mean += metric.call(r)}
		mean /= responses.count
		mean
	end
	
	def setup
		@screen_height = 900
		@width = width
		@height = height
#		@screen_transform = Transform.new({:x => 18.0, :y => -7500.0}, {:x => 100.0, :y => @screen_height})
		@screen_transform = Transform.new({:x => 10.0, :y => -750.0}, {:x => 500, :y => @screen_height})
		smooth
		no_loop
		background(0,0,0)
		color_mode(HSB, 1.0)

		responses = Response.find(:all)

		mean_x = mean(responses) {|r| r[:pre_total]}
		mean_y = mean(responses) {|r| r[:post_total]}
		
		mean = [[mean_x], [mean_y]]
		variance_x = variance(responses, ->(r){r[:pre_total]}, ->(r){r[:pre_total]})
		variance_y = variance(responses, ->(r){r[:post_total]}, ->(r){r[:post_total]})
		variance_xy = variance(responses, ->(r){r[:pre_total]}, ->(r){r[:post_total]})
		
		variance = [[variance_x, variance_xy], [variance_xy, variance_y]]
		gaussian = lambda do |x|
			(1.0/(2*Math::PI*Math.sqrt(variance.determinant))) * Math.exp(-0.5*(x.minus(mean).transpose*variance.inverse*x.minus(mean)).value)
		end


#		@c = CoordinateSystem.standard({:minimum => -60, :maximum => 60}, {:minimum => -60, :maximum => 60}, self)
#		@screen = Screen.new(@screen_transform, self, @c)

#		stroke(0.1,0.5,1)
#		fill(0.1,0.5,1)
		
	end

	def plot_distribution(responses, metric)
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

		@screen.join = true
		improvement_bins.keys.sort.each do|k|
			@screen.plot({:x => k, :y => improvement_bins[k]})
		end
		@screen.join = false
	end
	
	def draw
	end
end

w = 1200
h = 1000

#MySketch.send :include, Interactive
MySketch.new(:title => "My Sketch", :width => w, :height => h)


