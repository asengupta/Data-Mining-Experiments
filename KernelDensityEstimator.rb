require 'schema'
require 'basis_processing'
require 'distributions'

class MySketch < Processing::App
	app = self
	def setup
		color_mode(HSB, 1.0)
		@highlight_block = lambda do |p|
					rect_mode(CENTER)
					stroke(0.3,1,1)
					fill(0.3,1,1)
					rect(p[:x], p[:y], 5, 5)
				   end

		@passive_block = lambda do |p|
					rect_mode(CENTER)
					stroke(0.7,1,1)
					fill(0.7,1,1)
					rect(p[:x], p[:y], 5, 5)
				   end

		@screen_height = 900
		@width = width
		@height = height
		@screen_transform = Transform.new({:x => 10.0, :y => -7500.0}, {:x => 600.0, :y => @screen_height})
		no_loop
		smooth
		background(0,0,0)

		responses = Response.find(:all)

		bins = {}

#		57.times do |pre_score|
#			bins[pre_score] = responses.select {|r| r.pre_total == pre_score}.count
#		end
#		57.times do |post_score|
#			bins[post_score] = responses.select {|r| r.post_total == post_score}.count
#		end

		responses.each do |r|
			improvement = r.improvement
			bins[improvement] = bins[improvement] == nil ? 1 : bins[improvement] + 1
		end

		bins.each_pair do |k, v|
			bins[k] = v / responses.count.to_f
		end

		least_improvement = bins.keys.min
		most_improvement = bins.keys.max

		x_range = {:minimum => least_improvement, :maximum => most_improvement}
		y_range = {:minimum => bins.values.min, :maximum => bins.values.max}
		@c = CoordinateSystem.standard(x_range, y_range, self)
		@screen = Screen.new(@screen_transform, self, @c)

		stroke(0.2,1,1)
		fill(0.2,1,1)
		bins.each_pair do|k,v|
			@screen.plot({:x => k, :y => v})
		end
		
		kernels = {}
		bins.each_pair do |k,v|
			kernels[k] = {:kernel => Distributions.normal(k, 2.0), :n => v * responses.count}
		end
		stroke(0.3,1,1,0.4)
		fill(0.3,1,1,0.4)
		@screen.join = true
		bins.keys.sort.each do|k|
			v = estimate(kernels, k, responses.count)
			@screen.plot({:x => k, :y => v}, :track => true)
		end
		@screen.join = false
		rect_mode(CENTER)
		stroke(0.7,0.2,0.3)
		fill(0.7,0.2,0.3)
		kernels.each_value do |v|
			x = least_improvement.to_f
			while (x < most_improvement)
				@screen.join = true
				@screen.plot({:x => x, :y => v[:kernel].call(x) * v[:n] / responses.count}) {|p| point(p[:x], p[:y])}
				x += 0.1
			end
			@screen.join = false
		end
		color_mode(HSB, 1.0)
		stroke(0.9,0.0,1)
		fill(0.9,0.0,1)
		@screen.draw_axes(5,0.01)
		@index = @screen.build
	end
	
	def estimate(kernels, key, n)
		sum = 0.0
		kernels.each_pair do |k,v|
			sum += v[:kernel].call(key) * v[:n]
		end
		sum / n
	end
end

w = 1200
h = 1000

MySketch.send :include, Interactive
MySketch.new(:title => "Kernel Density Estimation", :width => w, :height => h)

