require 'set'
require 'schema'
require 'ranges'
require 'axis'
require 'ruby-processing'

class MySketch < Processing::App
	app = self
	def setup
		@width = width
		@height = height
		frame_rate(30)
		smooth
		background(0,0,0)
		color_mode(RGB, 1.0)

		responses = Response.find(:all)

		pre_bins = []
		post_bins = []

		56.times {pre_bins << 0}
		56.times {post_bins << 0}

		56.times do |pre_score|
			pre_bins[pre_score] = responses.select {|r| r.pre_total == pre_score}.count
		end
		56.times do |post_score|
			post_bins[post_score] = responses.select {|r| r.post_total == post_score}.count
		end

		x_unit_vector = {:x => 1.0, :y => 0}
		y_unit_vector = {:x => 0, :y => 1.0}

		
		x_scale = @width / ContinuousRange.new({:minimum => 0, :maximum => 56}).interval
		y_scale = @height / ContinuousRange.new({:minimum => 0, :maximum => 2000}).interval

		c = CoordinateSystem.new(x_unit_vector, y_unit_vector, [[10,0],[0,0.4]])
		stroke(1,1,0,1)
		fill(1,1,0)
		pre_bins.each_index do |position|
			standard_point = c.standard_basis({:x => position, :y => pre_bins[position]})
			ellipse(standard_point[:x] + 100, 800 - standard_point[:y], 5, 5)
		end

		stroke(0,1,0,1)
		fill(0,1,0)
		post_bins.each_index do |position|
			standard_point = c.standard_basis({:x => position, :y => post_bins[position]})
			ellipse(standard_point[:x] + 100, 800 - standard_point[:y], 5, 5)
		end
	end
	  
	def draw
	end
end

w = 1600
h = 1000

MySketch.new(:title => "My Sketch", :width => w, :height => h)


