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
		@screen_transform = Transform.new({:x => 500.0, :y => -300}, {:x => 500, :y => @screen_height/2})
		smooth
		no_loop
		background(0,0,0)
		color_mode(HSB, 1.0)

		@responses = Response.find(:all)

		@c = CoordinateSystem.standard({:minimum => -10, :maximum => 10}, {:minimum => 0.0, :maximum => 9000.0}, self)
		@screen = Screen.new(@screen_transform, self, @c)

		stroke(0.1,0.5,1)
		fill(0.1,0.5,1)
		
		l = -10
		@screen.join = true
		while (l < 1.0)
			transform = box_cox(l)
			jb_statistic = jb_stats(transform, @responses)
			@screen.plot({:x => l, :y => jb_statistic}, :track => true)
			l += 0.05
		end
#		transform = ->(x) {Math.log(x)}
#		jb_statistic = jb_stats(transform, @responses)

#		transform = ->(x) {x}
#		bins = {}
#		@responses.each do |r|
#			bins[r[:area]] = [] if bins[r[:area]].nil?
#			bins[r[:area]] << r
#		end
#		
#		puts bins.keys.count
#		aberrations = []
#		bins.each_pair do |k,v|
#			jb_statistic = jb_stats(transform, v)
#			puts "#{k}=#{jb_statistic}" if jb_statistic > 9.2103
#			aberrations << v if jb_statistic > 9.2103
#		end
#		@screen.join = false
#		aberrations.each do |a|
#			@screen.plot({:x => l, :y => jb_statistic}, :track => true)
#		end
		stroke(0.1,0.5,1)
		fill(0.1,0.5,1)
		@screen.draw_axes(0.2, 0.1)
	end
	
	def draw
	end
	
	def jb_stats(transform, responses)
		metric = lambda {|r| transform.call(r[:post_total])}

		n = responses.count.to_f
		mean = 0.0
		responses.each {|r| mean += metric.call(r)}
		mean /= responses.count

		mu4 = mu(responses, mean, 4, metric)
		mu3 = mu(responses, mean, 3, metric)
		variance = mu(responses, mean, 2, metric)
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
	
	def box_cox(l)
		lambda {|x|(Math.exp(x*l) - 1)/l}
	end
	
	def mu(samples, mean, order, met)
		sum = 0.0
		samples.each {|s| sum += (met.call(s) - mean)**order}
		sum/samples.count
	end
end

w = 1200
h = 1000

#MySketch.send :include, Interactive
MySketch.new(:title => "My Sketch", :width => w, :height => h)


