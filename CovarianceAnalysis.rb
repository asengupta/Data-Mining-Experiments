require 'rubygems'

Gem.clear_paths
ENV['GEM_HOME'] = '/home/avishek/jruby/jruby-1.6.3/lib/ruby/gems/1.8'
ENV['GEM_PATH'] = '/home/avishek/jruby/jruby-1.6.3/lib/ruby/gems/1.8'

class MySketch < Processing::App
	app = self
	def setup
		no_loop
		background(0,0,0)
		color_mode(RGB, 1.0)

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
		@color_scale = 1.0/max_positive_covariance
	end

	def draw
		@covariance_matrix.each_index do |row|
			@covariance_matrix[row].each_index do |column|
				scale = @covariance_matrix[row][column].abs * @color_scale
				fill(0,scale,0,1) if @covariance_matrix[row][column] >= 0
				fill(scale,0,0,1) if @covariance_matrix[row][column] < 0
				rect(column * 15, row * 15, 15, 15)
			end
		end
	end

	def covariance(inputs, dimension_1, dimension_2)
		sum = 0
		inputs.each {|input| sum += input[dimension_1] * input[dimension_2]}
		sum / inputs.length
	end
end

MySketch.new(:title => "Covariance Analysis", :width => 1000, :height => 1000)

