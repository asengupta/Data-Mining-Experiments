require 'rubygems'

Gem.clear_paths
ENV['GEM_HOME'] = '/home/avishek/jruby/jruby-1.6.4/lib/ruby/gems/1.8'
ENV['GEM_PATH'] = '/home/avishek/jruby/jruby-1.6.4/lib/ruby/gems/1.8'

require 'basis_processing'
require 'amqp'
require 'yaml'
require 'schema'
require 'set'

class CovarianceSketch < Processing::App
	app = self
	def setup
		@old_points = []
		@points_to_highlight = []
		no_loop
		background(0,0,0)
		color_mode(HSB, 1.0)

		means = Array.new(56)
		means.fill(0)

		inputs = []
		responses = Response.find(:all)
		responses.each do |r|
			bit_string = r[:post_performance].to_s(2).rjust(56, '0')
			response_as_bits = []
			bit_string.each_char do |bit|
				response_as_bits << (bit == '1'?1.0:0.0)
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

		@basis = CoordinateSystem.standard({:minimum => 0, :maximum => 55}, {:minimum => 0, :maximum => 55}, self)
		screen_transform = Transform.new({:x => 10, :y => -10}, {:x => 300, :y => 900})

		@screen = Screen.new(screen_transform, self, @basis)
		stroke(0,0,0)
		rect_mode(CENTER)
		@covariance_matrix.each_index do |row|
			@covariance_matrix[row].each_index do |column|
				scaled_color = @covariance_matrix[row][column].abs * @color_factor
				scaled_size = @covariance_matrix[row][column].abs * @size_factor
				fill(0.5,1,scaled_color) if @covariance_matrix[row][column] >= 0
				fill(0.0,1,scaled_color) if @covariance_matrix[row][column] < 0
				point = {:x => column, :y => row}
				@screen.plot(point, :track => true) {|o,m,s| rect(m[:x],m[:y],@size_scale,@size_scale)}
			end
		end
		@screen.draw_axes(10,10)
	end

	def draw
	end

	def covariance(inputs, dimension_1, dimension_2)
		sum = 0
		inputs.each {|input| sum += input[dimension_1] * input[dimension_2]}
		sum / inputs.length
	end
end

CovarianceSketch.send(:include, Interactive)
CovarianceSketch.new(:title => "Covariance Analysis", :width => 1400, :height => 1000)

