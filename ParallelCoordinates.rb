require 'schema'
require 'set'
require 'ranges'
require 'axis'
require 'ruby-processing'

include Math

class MySketch < Processing::App
	app = self
	def setup
		frame_rate(30)
		smooth
		background(0,0,0)
		color_mode(RGB, 1.0)

		responses = Response.find(:all)
		responses = responses[0..1500]
		@height = height
		@width = width
		@inputs = []
		@dimensions = {:language => Set.new, :gender => Set.new, :area => Set.new}
		@samples_to_highlight = []

		responses.each do |r|
			record = {:language => r.language, :gender => r.gender, :before => r.pre_total, :after => r.post_total, :id => r.student_id, :area => r.area}
			@dimensions[:language].add(r.language)
			@dimensions[:gender].add(r.gender)
			@dimensions[:area].add(r.area)
			@inputs << record
		end

		@inputs = @inputs[0..13000]
		@dimensions[:language] = @dimensions[:language].to_a
		@dimensions[:gender] = @dimensions[:gender].to_a
		@dimensions[:area] = @dimensions[:area].to_a

		@axes = [:language, :gender, :area, :before, :after]
		@x_axis = Axis.new(@width, DiscreteRange.new({:values => @axes}), 0, 1, 0)
		@y_axes =
		{
			:language => Axis.new(@height, DiscreteRange.new({:values => @dimensions[:language]}), @height, -1, 90),
			:gender => Axis.new(@height, DiscreteRange.new({:values => @dimensions[:gender]}), @height, -1, 90),
			:area => Axis.new(@height, DiscreteRange.new({:values => @dimensions[:area]}), @height, -1, 90),
			:before => Axis.new(@height, ContinuousRange.new({:minimum => 0.0, :maximum => 56.0}), @height, -1, 90),
			:after => Axis.new(@height, ContinuousRange.new({:minimum => 0.0, :maximum => 56.0}), @height, -1, 90)
		}
		@all_samples = []
		@inputs.each do |input|
			last_x = last_y = 0
			lines = []
			@axes.each_index do |axis_index|
				axis = @axes[axis_index]
				y = @y_axes[axis].transform(input[axis])
				axis_x = @x_axis.transform(axis)
				lines << {:from => {:x => last_x, :y => last_y}, :to => {:x => axis_x, :y => y}}
				last_x = axis_x
				last_y = y
			end
			sample = Sample.new(lines, self)
			@all_samples << sample
			sample.clear
		end
	  end
	  
	def draw
		draw_axes
		return if mouseX == 0 && mouseY == 0
		@samples_to_highlight.each {|s| s.clear}
		@samples_to_highlight = @all_samples.select do |s|
			s.intersects(mouseX, mouseY)
		end

		@samples_to_highlight.each {|s| s.draw}
	end

	def draw_axes
		stroke(1,1,1,1)
		@axes.each do |axis|
			x = @x_axis.transform(axis)
			line(x, 0, x, @height)
		end
	end

	class Sample
		def initialize(lines, parent)
			@lines = lines
		end

		def intersects(x,y)
			for l in @lines
				smaller_y = [l[:from][:y], l[:to][:y]].min
				larger_y = [l[:from][:y], l[:to][:y]].max
				next if !(mouseX>=l[:from][:x] && mouseX<=l[:to][:x] && mouseY>=smaller_y && mouseY<=larger_y)
				m = (l[:to][:y] - l[:from][:y]).to_f/(l[:to][:x] - l[:from][:x]).to_f
				next if (m*mouseX - mouseY + l[:from][:y] - m*l[:from][:x]).abs > 1.5
				return true
			end
			false
		end

		def draw
			stroke(1,1,1,1)
			@lines.each do |l|
				line(l[:from][:x], l[:from][:y], l[:to][:x], l[:to][:y])
			end
		end

		def clear
			stroke(0.1,0.1,0.1,1)
			@lines.each do |l|
				line(l[:from][:x], l[:from][:y], l[:to][:x], l[:to][:y])
			end
		end
	end
end


h = 800
w = 1400
MySketch.new(:title => "My Sketch", :width => w, :height => h)


