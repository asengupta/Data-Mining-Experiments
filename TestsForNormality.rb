require 'rubygems'
require 'active_record'


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
#		@screen_transform = Transform.new({:x => 18.0, :y => -7500.0}, {:x => 100.0, :y => @screen_height})
		@screen_transform = Transform.new({:x => 500.0, :y => -0.1}, {:x => 100, :y => @screen_height})
		smooth
		no_loop
		background(0,0,0)
		color_mode(HSB, 1.0)

		@responses = Response.find(:all)

		@c = CoordinateSystem.standard({:minimum => 0, :maximum => 10}, {:minimum => 0.0, :maximum => 9000.0}, self)
		@screen = Screen.new(@screen_transform, self, @c)

		stroke(0.1,0.5,1)
		fill(0.1,0.5,1)
		
		l = 0.1
		@screen.join = true
		while (l < 1.5)
			transform = box_cox(l)
			jb_statistic = jb_stats(transform)
			@screen.plot({:x => l, :y => jb_statistic}, :track => true)
			if (l >= 0.4 && l <= 0.5)
				l+= 0.00625
			else
				l += 0.025
			end
		end
		transform = ->(x) {Math.log(x)}
		jb_statistic = jb_stats(transform)
		@screen.join = false
		@screen.plot({:x => l, :y => jb_statistic}, :track => true)
		
		stroke(0.1,0.5,1)
		fill(0.1,0.5,1)
		@screen.draw_axes(0.2, 400)
	end
	
	def draw
	end
	
	def jb_stats(transform)
		metric = lambda {|r| transform.call(r.improvement + 57)}

		n = @responses.count.to_f
		mean = 0.0
		@responses.each {|r| mean += metric.call(r)}
		mean /= @responses.count

		mu4 = mu(@responses, mean, 4, metric)
		mu3 = mu(@responses, mean, 3, metric)
		variance = mu(@responses, mean, 2, metric)
		alpha3 = Math.sqrt(variance)**3
		alpha4 = variance**2

		s = mu3.to_f/alpha3
		k = mu4.to_f/alpha4 - 3

		jb = n/6 * (s**2 + 0.25 * (k-3)**2)
		puts "JB statistic = #{jb}"
		jb
#		puts "n = #{n}"
#		puts "Skewness = #{s}"
#		puts "Kurtosis = #{k}"
#		puts "JB statistic = #{jb}"
	end
	
	def box_cox(l)
		lambda {|x|(x**l - 1)/l}
	end
	
	def mu(samples, mean, order, met)
		sum = 0.0
		samples.each {|s| sum += (met.call(s) - mean)**order}
		sum/samples.count
	end
end

w = 1200
h = 1000

MySketch.send :include, Interactive
MySketch.new(:title => "My Sketch", :width => w, :height => h)


