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
			rect(m[:x], m[:y], 10, 10)
		end
		@screen_height = 900
		@width = width
		@height = height
		@screen_transform = Transform.new({:x => 10.0, :y => -10.0}, {:x => 500, :y => @screen_height})
		smooth
		no_loop
		background(0,0,0)
		color_mode(HSB, 1.0)

		responses = Response.find(:all)

		@c = CoordinateSystem.standard({:minimum => 0, :maximum => 60}, {:minimum => 0, :maximum => 60}, self)
		@screen = Screen.new(@screen_transform, self, @c)

		stroke(0.1,0.5,1)
		fill(0.1,0.5,1)
		plot_distribution(responses, ->(r) {r[:pre_total]}, ->(r) {r[:post_total]})

		@screen.draw_axes(5, 5)
	end

	def plot_distribution(responses, x_metric, y_metric)
		array = []
		57.times do |r|
			row = Array.new(57)
			row.fill(0)
			array << row
		end
		responses.each do |r|
			array[y_metric.call(r)][x_metric.call(r)] += 1
		end
		array.each_index do |r|
			array[r].each_index do |c|
				b = 500 * array[r][c]/28000.0
				stroke(0.1,0.5,b)
				fill(0.1,0.5,b)
				@screen.plot({:x => c, :y => r}, :track => true)
			end
		end
end
	
	def draw
	end
end

w = 1200
h = 1000

MySketch.send :include, Interactive
MySketch.new(:title => "My Sketch", :width => w, :height => h)


