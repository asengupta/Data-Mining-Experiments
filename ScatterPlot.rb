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
		@c = CoordinateSystem.standard({:minimum => 0, :maximum => 60}, {:minimum => -60, :maximum => 60}, self)
		@screen_transform = Transform.new({:x => 8.0, :y => -8.0}, {:x => 500, :y => @screen_height/2 + 50})
		@screen = Screen.new(@screen_transform, self, @c)

		stroke(0.1,0.5,1)
		fill(0.1,0.5,1)
		
		plot_distribution(responses, ->(r) {Math.log(r[:pre_total])}, ->(r) {r.improvement})
		@screen.draw_axes(5, 5, :gridlines => false)
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
		array.each_key do |r|
			array[r].each_key do |c|
				b = 500 * array[r][c]/28000.0
				stroke(0.5,0.5,0.07)
				fill(0.1,0.5,b)
				@screen.plot({:x => c, :y => r, :value => array[r][c]}) do |o,m,s|
					rect_mode(CENTER)
					rect(m[:x], m[:y], 8, 8)
				end
			end
		end
#		responses.each do |r|
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


