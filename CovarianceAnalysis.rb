require 'rubygems'

Gem.clear_paths
ENV['GEM_HOME'] = '/home/avishek/jruby/jruby-1.6.3/lib/ruby/gems/1.8'
ENV['GEM_PATH'] = '/home/avishek/jruby/jruby-1.6.3/lib/ruby/gems/1.8'

require 'basis_processing'
require 'amqp'
require 'yaml'

class MySketch < Processing::App
	app = self
	def setup
		@old_rectangles = []
		@rectangles_to_highlight = []
		no_loop
		background(0,0,0)
		color_mode(HSB, 1.0)

		means = Array.new(56)
		means.fill(0)

		handle = File.open('/home/avishek/Code/DataMiningExperiments/csv/Ang2010TestsModified.csv', 'r')
		inputs = []
		handle.each_line do |line|
			split_elements = line.split('|')
			pre_test_responses = split_elements[8..63].collect {|e| e.to_f}
			response_as_bits = []
			pre_test_responses.each do |r|
				response_as_bits << r
			end
			inputs << response_as_bits
		end

		samples = inputs.count
#		samples = 20
		inputs = inputs[1..samples]
		inputs.each do |input|
			56.times do |i|
				means[i] += input[i]
			end
		end

		means = means.collect {|t| t/samples}

		inputs.each do |input|
			56.times do |i|
				input[i] -= means[i]
			end
		end

		@covariance_matrix = []

		max_positive_covariance = 0
		56.times do |row|
			matrix_row = []
			56.times do |column|
				cov = covariance(inputs, row, column)
				max_positive_covariance = cov.abs if cov >= 0 && cov.abs > max_positive_covariance
				matrix_row << cov
			end
			@covariance_matrix << matrix_row
		end
		@size_scale = 15
		@color_factor = 1.0/max_positive_covariance
		@size_factor = @size_scale /max_positive_covariance

		@scale = 10

		x_basis_vector = {:x => 1.0, :y => 0.0}
		y_basis_vector = {:x => 0.0, :y => 1.0}

		x_range = ContinuousRange.new({:minimum => 0, :maximum => 55})
		y_range = ContinuousRange.new({:minimum => 0, :maximum => 55})

		@basis = CoordinateSystem.new(Axis.new(x_basis_vector,x_range), Axis.new(y_basis_vector,y_range), [[@size_scale,0],[0,@size_scale]], self)
		screen_transform = SignedTransform.new({:x => 1, :y => -1}, {:x => 300, :y => 900})

		@screen = Screen.new(screen_transform, self)
		stroke(0,0,0)
		rect_mode(CENTER)
		@covariance_matrix.each_index do |row|
			@covariance_matrix[row].each_index do |column|
				scaled_color = @covariance_matrix[row][column].abs * @color_factor
				scaled_size = @covariance_matrix[row][column].abs * @size_factor
				fill(0.5,1,scaled_color) if @covariance_matrix[row][column] >= 0
				fill(0.0,1,scaled_color) if @covariance_matrix[row][column] < 0
				point = {:x => column, :y => row}
				@screen.plot(point, @basis) {|point| rect(point[:x],point[:y],@size_scale,@size_scale)}
			end
		end
		@screen.draw_axes(@basis,10,10)

		Thread.new do
			puts "Inside: #{Thread.current}"
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
				  	exchange.publish("#{YAML::dump(@rectangles_to_highlight || [])}", :routing_key => 'lambda_response')
					puts "Published."
				end
			end
		end
	end

	def evaluate(message)
		begin
			b = eval(message)
			puts b
			@rectangles_to_highlight = []
			@covariance_matrix.each_index {|r| @covariance_matrix[r].each_index {|c| @rectangles_to_highlight << {:y => r, :x => c} if r!= c && b.call(@covariance_matrix[r][c])}}
			redraw
		rescue => e
			puts e
		end
	end

	def draw
		stroke(0,0,0)
		@old_rectangles.each do |old|
			scaled_color = @covariance_matrix[old[:y]][old[:x]].abs * @color_factor
			fill(0.5,1,scaled_color)
			@screen.plot(old, @basis) {|p| rect(p[:x],p[:y],@size_scale,@size_scale)}
		end
		@rectangles_to_highlight.each do |new_rectangle|
			next if new_rectangle[:x] == new_rectangle[:y]
			fill(0.1,1,1)
			@screen.plot(new_rectangle, @basis) {|p| rect(p[:x],p[:y],@size_scale,@size_scale)}
		end
		@old_rectangles = @rectangles_to_highlight
		@screen.draw_axes(@basis,10,10)
	end

	def mouseMoved
		original_point = @screen.original({:x => mouseX, :y => mouseY}, @basis)
		original_point = {:x => original_point[:x].round, :y => original_point[:y].round}
		puts original_point.inspect
		return if original_point[:x] > 55 || original_point[:y] > 55 || original_point[:x] < 0 || original_point[:y] < 0
		@rectangles_to_highlight = [{:x => original_point[:x].round, :y => original_point[:y].round}]
		redraw
	end

	def covariance(inputs, dimension_1, dimension_2)
		sum = 0
		inputs.each {|input| sum += input[dimension_1] * input[dimension_2]}
		sum / inputs.length
	end
end

MySketch.new(:title => "Covariance Analysis", :width => 1400, :height => 1000)

