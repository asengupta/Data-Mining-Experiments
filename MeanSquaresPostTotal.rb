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
#		@screen_transform = Transform.new({:x => 18.0, :y => -7500.0}, {:x => 100.0, :y => @screen_height})
		@screen_transform = Transform.new({:x => 500.0, :y => -7500.0}, {:x => 500, :y => @screen_height})
		smooth
		no_loop
		background(0,0,0)
		color_mode(HSB, 1.0)

		responses = Response.find(:all)

		@c = CoordinateSystem.standard({:minimum => -60, :maximum => 60}, {:minimum => 0.0, :maximum => 0.12}, self, {:x => 'Score', :y => 'Probability'})
		@screen = Screen.new(@screen_transform, self, @c)

		stroke(0.4,0.5,1)
		fill(0.4,0.5,1)
		plot_distribution(responses, ->(r) {r[:pre_total]}, "Pre-Total")
		@screen.join=true
		color_mode(RGB, 1.0)
		@screen.draw_axes(0.1, 0.01)
	end

	def box_cox(l)
		->(x) {(x**l - 1)/l}
	end
	
	def plot_distribution(responses, metric, legend)
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

		points = []
		l = 0.01
		p = ->(x) {l * Math.exp(-l*(56-x))}
		improvement_bins.keys.sort.each do|k|
			points << {:x => k, :y => improvement_bins[k]}
		end
		
		mse_data = []
		while l <= 1.2
			mse = 0
			improvement_bins.keys.sort.each do|k|
				mse += (p.call(k) - improvement_bins[k])**2
				puts mse
			end
			mse_data << {:x => l, :y => mse}
			l += 0.01
		end
		@screen.join = true
		@screen.plot(points, :track => true, :legend => legend)
		@screen.join = false
		@screen.join = true
		@screen.plot(mse_data, :track => true, :legend => legend)
		@screen.join = false
	end
	
	def draw
	end
end

w = 1200
h = 1000

MySketch.send :include, Interactive
MySketch.new(:title => "Shape of Score Data", :width => w, :height => h)


