require 'rubygems'

Gem.clear_paths
ENV['GEM_HOME'] = '/home/avishek/jruby/jruby-1.6.3/lib/ruby/gems/1.8'
ENV['GEM_PATH'] = '/home/avishek/jruby/jruby-1.6.3/lib/ruby/gems/1.8'
require 'schema'
require 'set'
require 'ruby-processing'
require 'basis_processing'
require 'amqp'

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
		@screen_transform = SignedTransform.new({:x => 10, :y => -1}, {:x => 0, :y => @height})
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
			:language => @height / @y_ranges[:language].interval.to_f,
			:gender => @height / @y_ranges[:gender].interval.to_f,
			:area => @height / @y_ranges[:area].interval.to_f,
			:before => @height / @y_ranges[:before].interval.to_f,
			:after => @height / @y_ranges[:after].interval.to_f
		}

		x_axis = Axis.new(x_unit_vector,@x_range)

		@systems =
		{
			:language => CoordinateSystem.new(x_axis, Axis.new(y_unit_vector,@y_ranges[:language]), self, [[@width/@axes.count, 0],[0, @scales[:language]]]),
			:gender => CoordinateSystem.new(x_axis, Axis.new(y_unit_vector,@y_ranges[:gender]), self, [[@width/@axes.count, 0],[0, @scales[:gender]]]),
			:area => CoordinateSystem.new(x_axis, Axis.new(y_unit_vector,@y_ranges[:area]), self, [[@width/@axes.count, 0],[0, @scales[:area]]]),
			:before => CoordinateSystem.new(x_axis, Axis.new(y_unit_vector,@y_ranges[:before]), self, [[@width/@axes.count, 0],[0, @scales[:before]]]),
			:after => CoordinateSystem.new(x_axis, Axis.new(y_unit_vector,@y_ranges[:after]), self, [[@width/@axes.count, 0],[0, @scales[:after]]])
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
				lines << {:from => @screen_transform.apply({:x => last_x, :y => last_y}), :to => @screen_transform.apply({:x => x, :y => y})}
				last_x = x
				last_y = y
			end
			sample = Sample.new(lines, self, input)
			@all_samples << sample
			sample.clear
		end

		Thread.new do
			EventMachine.run do
				connection = AMQP.connect(:host => '127.0.0.1', :port => 5672)
			  	puts "Connected to AMQP broker. Running #{AMQP::VERSION} version of the gem..."
			  	channel = AMQP::Channel.new(connection)
			  	exchange = channel.direct('lambda_exchange', :auto_delete => true)
				queue = channel.queue('lambda', :auto_delete => true)
				answer_queue = channel.queue('lambda_response', :auto_delete => true)
			  	queue.bind(exchange, :routing_key => 'lambda')
			  	answer_queue.bind(exchange, :routing_key => 'lambda_response')

				queue.subscribe do |message|
					evaluate(message)
				  	exchange.publish("OK - #{(@samples_to_highlight || []).count} samples.", :routing_key => 'lambda_response')
				end
			end
		end
	end
	  
	def mouseMoved
		return if mouseX == 0 && mouseY == 0
		@samples_to_highlight = @all_samples.select do |s|
			s.intersects(mouseX, mouseY)
		end
		redraw
	end

	def evaluate(message)
		begin
			b = eval(message)
			@samples_to_highlight = @all_samples.select {|sample| b.call(sample.data)}
			redraw
		rescue => e
			puts e
		end
	end

	def draw
		@old_highlighted_samples.each {|s| s.clear} if @old_highlighted_samples != nil
		@samples_to_highlight.each {|s| s.draw}
		@old_highlighted_samples = Array.new(@samples_to_highlight)
		draw_axes
		$stdout.print "\r#{@samples_to_highlight.count} samples selected OK."
		$stdout.flush
	end

	def draw_axes
		stroke(1,1,1,1)
		@axes.each_index do |axis_index|
			axis = @axes[axis_index]
			axis_top = @systems[axis].standard_basis({:x => @x_range.index(axis), :y => 0})
			axis_bottom = @systems[axis].standard_basis({:x => @x_range.index(axis), :y => @height})
			line(axis_top[:x], axis_top[:y], axis_bottom[:x], axis_bottom[:y])
		end
	end

	class Sample
		attr_accessor :data
		def initialize(lines, parent, data)
			@lines = lines
			@data = data
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
			stroke(0.01,0.01,0.01,1)
			@lines.each do |l|
				line(l[:from][:x], l[:from][:y], l[:to][:x], l[:to][:y])
			end
		end
	end
end


h = 800
w = 1400
MySketch.new(:title => "My Sketch", :width => w, :height => h)


