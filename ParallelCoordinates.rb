require 'schema'
require 'set'
require 'ruby-processing'
require 'basis_processing'
gem 'rabbitmq-jruby-client'
require 'rabbitmq_client'

include Math

class MySketch < Processing::App
	app = self
	def setup
		frame_rate(30)
		no_loop
		smooth
		background(0,0,0)
		color_mode(RGB, 1.0)

		responses = Response.find(:all)
		responses = responses[0..1500]
		@height = height
		@width = width
		screen_transform = SignedTransform.new({:x => 10, :y => -1}, {:x => 0, :y => @height})
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
		x_unit_vector = {:x => 1, :y => 0}
		y_unit_vector = {:x => 0, :y => 1}

		@x_range = DiscreteRange.new({:values => @axes})
		language_range = DiscreteRange.new({:values => @dimensions[:language]})
		gender_range = DiscreteRange.new({:values => @dimensions[:gender]})
		area_range = DiscreteRange.new({:values => @dimensions[:area]})
		before_range = ContinuousRange.new({:minimum => 0.0, :maximum => 56.0})
		after_range = ContinuousRange.new({:minimum => 0.0, :maximum => 56.0})
		@y_ranges =
		{
			:language => language_range,
			:gender => gender_range,
			:area => area_range,
			:before => before_range,
			:after => after_range
		}
		@scales =
		{
			:language => @height / @y_ranges[:language].interval,
			:gender => @height / @y_ranges[:gender].interval,
			:area => @height / @y_ranges[:area].interval,
			:before => @height / @y_ranges[:before].interval,
			:after => @height / @y_ranges[:after].interval
		}

		x_axis = Axis.new(x_unit_vector,@x_range)

		@systems =
		{
			:language => CoordinateSystem.new(x_axis, Axis.new(y_unit_vector,@y_ranges[:language]), [[@width/@axes.count, 0],[0, @scales[:language]]], self),
			:gender => CoordinateSystem.new(x_axis, Axis.new(y_unit_vector,@y_ranges[:gender]), [[@width/@axes.count, 0],[0, @scales[:gender]]], self),
			:area => CoordinateSystem.new(x_axis, Axis.new(y_unit_vector,@y_ranges[:area]), [[@width/@axes.count, 0],[0, @scales[:area]]], self),
			:before => CoordinateSystem.new(x_axis, Axis.new(y_unit_vector,@y_ranges[:before]), [[@width/@axes.count, 0],[0, @scales[:before]]], self),
			:after => CoordinateSystem.new(x_axis, Axis.new(y_unit_vector,@y_ranges[:after]), [[@width/@axes.count, 0],[0, @scales[:after]]], self)
		}

		@all_samples = []
		@inputs.each do |input|
			last_x = last_y = 0
			lines = []
			@axes.each_index do |axis_index|
				axis = @axes[axis_index]
				standard_point = @systems[axis].standard_basis({:x => @x_range.index(axis), :y => @y_ranges[axis].index(input[axis])})
				y = standard_point[:y]
				x = standard_point[:x]
				if axis_index == 0
					last_x = x
					last_y = y
				end
				lines << {:from => screen_transform.apply({:x => last_x, :y => last_y}), :to => screen_transform.apply({:x => x, :y => y})}
				last_x = x
				last_y = y
			end
			sample = Sample.new(lines, self)
			@all_samples << sample
			sample.clear
		end
		@client = RabbitMQClient.new
		@queue = @client.queue('lambda')
		@exchange = @client.exchange('lambda_exchange')
		@queue.bind(@exchange)
	  end
	  
	def mouseMoved
		redraw
	end

	def draw
		p "Binding complete"
#		message = @queue.retrieve
#		p message
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
			x = @x_axis.transform(@x_axis.index(axis))
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


