require 'schema'
require 'set'
require 'ruby-processing'

include Math
class Blah < Processing::App
	def setup
		frame_rate(30)
		smooth
		background(0,0,0)
		color_mode(RGB, 255)
		responses = Response.find(:all)
		responses = responses[0..200]
		map = SelfOrganisingMap.new(responses, 200, 200, :radius_of_effect => 45)
		map.go(20)
		map.map.each_index do |row|
			map.map[row].each_index do |column|
				intensity = map.map[row][column] * 5
				stroke(0,intensity,0)
				point(column, row)
			end
		end
		stroke(255,0,0)
		map.markers.each_index do |row|
			map.markers[row].each_index do |column|
				point(column, row) if map.markers[row][column] == '0'
			end
		end
	end

end

class SelfOrganisingMap
	attr_accessor :map, :markers
	def initialize(inputs, width, height, options)
		@radius_of_effect = options[:radius_of_effect]
		@inputs = []
		inputs.each do |r|
			@inputs << { :area => r[:area], :vector => r[:pre_total]}
		end
		@rows = height
		@columns = width

		@rings = circle_hash(@radius_of_effect)
		@map = initialised_map(@rows, @columns)
		@markers = points(@rows, @columns)
		@data_points = []
		puts "Done initialising map\n"
	end

	def discrete_circle(radius)
		points = Set.new
		all_points = []
		radius.times do |y|
			y = y.to_f + 1
			x = radius * Math.cos(Math.asin(y/radius))
			points.add({:x => x.ceil, :y => y.ceil})
			points.add({:x => x.ceil, :y => y.floor})
			points.add({:x => x.floor, :y => y.ceil})
			points.add({:x => x.floor, :y => y.floor})
		end
		radius.times do |x|
			x = x.to_f + 1
			y = radius * Math.sin(Math.acos(x/radius))
			points.add({:x => x.ceil, :y => y.ceil})
			points.add({:x => x.ceil, :y => y.floor})
			points.add({:x => x.floor, :y => y.ceil})
			points.add({:x => x.floor, :y => y.floor})
		end
	
		points = points.to_a
		all_points << points
		all_points << points.collect {|p| {:x => -p[:x], :y => p[:y]}}
		all_points << points.collect {|p| {:x => -p[:x], :y => -p[:y]}}
		all_points << points.collect {|p| {:x => p[:x], :y => -p[:y]}}
		all_points.flatten
	end

	def points(rows, columns)
		map = []
		rows.times do |r|
			row = []
			columns.times.each do |c|
				row<< ' '
			end
			map<< row
		end
		map
	end

	def initialised_map(rows, columns)
		map = []
		rows.times do |r|
			row = []
			columns.times.each do |c|
				row<< rand(rand(56))
			end
			map<< row
		end
		map
	end

	def circle_hash(rof)
		hash = {}
		rof.times do |r|
			hash[r+1] = discrete_circle(r+1)
		end
		hash[0] = [{:x => 0, :y => 0}]
		hash
	end

	def eta(iteration)
		500 * Math.exp(- iteration / 2)
	end

	def go(iterations)
		iterations.times do |iteration|
			data_points = []
			@inputs.each do |sample|
				input = sample[:vector]
				closest = {:row => 0, :column => 0}
				smallest_distance = (map[0][0] - input).abs
				@map.each_index do |row|
					@map[row].each_index do |column|
						distance = (map[row][column] - input).abs
						next if distance >= smallest_distance
						closest = {:row => row, :column => column}
						smallest_distance = distance
					end
				end
				@data_points << {:x => closest[:column], :y => closest[:row]}
				@radius_of_effect.times do |radius|
					@rings[radius].each do |neighbor|
						neighbor_x = closest[:column] + neighbor[:x]
						neighbor_y = closest[:row] + neighbor[:y]
						next if (neighbor_y < 0 || neighbor_x < 0 || neighbor_y >= @rows || neighbor_x >= @columns)
						distance = (map[neighbor_y][neighbor_x] - input).abs
						path = (input - map[neighbor_y][neighbor_x])
						steps_to_adjust = path * Math.exp(- (radius**2)/eta(iteration))
						@map[neighbor_y][neighbor_x] += steps_to_adjust
					end
				end

				@markers[closest[:row]][closest[:column]] = '0' if iteration == iterations - 1
			end
			p "Iteration #{iteration}"
		end

	end
end

Blah.new(:title => "My Sketch", :width => 500, :height => 500)

