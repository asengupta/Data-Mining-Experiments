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
	
	def variance(samples, mean_x, mean_y, x_metric, y_metric)
		sum = 0.0
		samples.each {|s| sum += (x_metric.call(s) - mean_x)*(y_metric.call(s) - mean_y)}
		sum/samples.count
	end

	def setup
		@screen_height = 900
		@width = width
		@height = height
#		@screen_transform = Transform.new({:x => 18.0, :y => -7500.0}, {:x => 100.0, :y => @screen_height})
		@screen_transform = Transform.new({:x => 10.0, :y => -10.0}, {:x => 500, :y => @screen_height})
		smooth
		no_loop
		background(0,0,0)
		color_mode(HSB, 1.0)

		responses = Response.find(:all)

		mean_x = mean(responses) {|r| r[:pre_total]}
		mean_y = mean(responses) {|r| r[:post_total]}
		
		mean = Matrix.columns([[mean_x, mean_y]])
		variance_x = variance(responses, mean_x, mean_y, ->(r){r[:pre_total]}, ->(r){r[:pre_total]})
		variance_y = variance(responses, mean_x, mean_y, ->(r){r[:post_total]}, ->(r){r[:post_total]})
		variance_xy = variance(responses, mean_x, mean_y, ->(r){r[:pre_total]}, ->(r){r[:post_total]})
		
		variance_matrix = Matrix.rows([[variance_x, variance_xy], [variance_xy, variance_y]])
		gaussian = lambda do |x|
			x = x.as_matrix
			wut = (x - mean).transpose
			wut *= variance_matrix.inverse
			wut *= (x - mean)
			(1.0/(2*Math::PI*Math.sqrt(variance_matrix.determinant))) * Math.exp(-0.5*wut[0,0])
		end

		x_start = mean_x - 70
		x_end = mean_x + 70
		y_start = mean_y - 70
		y_end = mean_y + 70
		y = y_start
		
		@c = CoordinateSystem.standard({:minimum => -60, :maximum => 60}, {:minimum => -60, :maximum => 60}, self)
		@screen = Screen.new(@screen_transform, self, @c)
		rect_mode(CENTER)
		while y <= y_end
			x = x_start
			while x <= x_end
				p = {:x => x, :y => y}
				v = gaussian.call(p)
				stroke(0.1,0.5,0.3)
				fill(0.1,0.5,v*700)
				@screen.plot(p) {|o,m,s| rect(m[:x], m[:y], 10, 10)}
				x += 1.0
			end
			y += 1.0
		end
		@screen.draw_axes(10,10)
	end

	def draw
	end
end

w = 1200
h = 1000

#MySketch.send :include, Interactive
MySketch.new(:title => "My Sketch", :width => w, :height => h)


