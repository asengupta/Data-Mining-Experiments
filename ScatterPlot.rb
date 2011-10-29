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
		smooth
		no_loop
		background(0,0,0)
		color_mode(HSB, 1.0)

		responses = Response.find(:all)
		bins = {}
		responses.each do |r|
			bins[r[:language]] = [] if bins[r[:language]].nil?
			bins[r[:language]] << r
		end

#		@c = CoordinateSystem.standard({:minimum => 0.0, :maximum => 3.0}, {:minimum => 0.0, :maximum => 3.0}, self)
		@c = CoordinateSystem.standard({:minimum => 0, :maximum => 60}, {:minimum => 0, :maximum => 60}, self, {:x => 'Pre-Intervention Total', :y => 'Post-Intervention Total'})
		@screen_transform = Transform.new({:x => 8, :y => -8}, {:x => 500, :y => @screen_height/2 + 50})
		@screen = Screen.new(@screen_transform, self, @c)

		stroke(0.1,0.5,1)
		fill(0.1,0.5,1)
		
		plot_distribution(responses, ->(r) {r[:pre_total]}, ->(r) {r[:post_total]})
		@screen.draw_axes(10, 10)
	end

	def plot_distribution(responses, x_metric, y_metric)
		array = {}
		responses.each do |r|
			y = y_metric.call(r)
			x = x_metric.call(r)
			
			array[y] = {} if array[y].nil?
			array[y][x] = 0 if array[y][x].nil?
			array[y][x] += 1
		end
		rect_mode(CENTER)
		array.each_key do |r|
			array[r].each_key do |c|
				b = 500 * array[r][c]/28000.0
				stroke(0.5,0.5,0.07)
				fill(0.3,0.5,b)
				@screen.plot({:x => c, :y => r, :value => array[r][c]}, :track => true) {|o,m,s| rect(m[:x], m[:y], 8, 8)}
			end
		end
		
		sigma_x = 0.0
		sigma_y = 0.0
		sigma_x2 = 0.0
		sigma_xy = 0.0
		
		puts "sigma_x=#{sigma_x}, sigma_y=#{sigma_y}, sigma_x2=#{sigma_x2}, sigma_xy=#{sigma_xy}"
		responses.each do |r|
			y = y_metric.call(r)
			x = x_metric.call(r)
			sigma_xy += x*y
			sigma_x += x
			sigma_y += y
			sigma_x2 += x**2
		end

		puts "sigma_x=#{sigma_x}, sigma_y=#{sigma_y}, sigma_x2=#{sigma_x2}, sigma_xy=#{sigma_xy}"
		n = responses.count.to_f
		m = (n*sigma_xy - sigma_x*sigma_y)/(n*sigma_x2 - sigma_x**2)
		c = (sigma_y - m*sigma_x)/n

		puts "m=#{m}, c=#{c}"
		x = 0.0

		fill(0.1,1,1)
		while (x <= 56)
			@screen.plot({:x => x, :y => m*x + c}, :join => true) {|o,m,s|}
			x += 0.1
		end

#		responses.each do |r|
#			fill(0.3,1,)
#			@screen.plot({:x => x_metric.call(r), :y => y_metric.call(r)})
#		end
end
	
	def draw
	end
end

w = 1200
h = 1000

MySketch.send :include, Interactive
MySketch.new(:title => "My Sketch", :width => w, :height => h)


