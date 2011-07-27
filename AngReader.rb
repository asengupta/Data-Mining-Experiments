require 'set'
require 'BitwiseOperations'
require 'RMagick'

include Magick
include BitwiseOperations

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

handle = File.open('/home/avishek/BitwiseOperations/Ang2010TestsModified.csv', 'r')
inputs = []
handle.each_line do |line|
	split_elements = line.split('|')
	pre_test_responses = split_elements[8..63].collect {|e| e.to_i}
	response_as_64 = 0
	pre_test_responses.each do |r|
		response_as_64+= 1 if r == 1
		response_as_64 <<= 1
	end
	inputs << { :area => split_elements[0], :vector => response_as_64}
end


p "Done reading"

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
			row<< rand(2**57 - 1)
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

rows = 70
columns = 70
radius_of_effect = 20
inputs = inputs[1..200]

rings = circle_hash(radius_of_effect)
map = initialised_map(rows, columns)
markers = points(rows, columns)
data_points = []
puts "Done initialising map\n"

index = 0
iterations = 20
animated_gif = ImageList.new
animated_gif.delay= 1000

f = Image.new(columns,rows) { self.background_color = "black" }
map.each_index do |row|
	map[row].each_index do |column|
		h = hamming_distance_64(map[row][column], 0)
		intensity = hamming_distance_64(map[row][column], 0) * 4
#		p "Distance between 0 and #{map[row][column]} is #{h}"
		f.pixel_color(column, row, "rgb(0,#{intensity},0)")
	end
end

f.write("som/initial.jpg")

iterations.times do |iteration|
	f = Image.new(columns,rows) { self.background_color = "black" }
	data_points = []
	inputs.each do |sample|
		input = sample[:vector]
		closest = {:row => 0, :column => 0}
		smallest_distance = hamming_distance_64(map[0][0], input)
		map.each_index do |row|
			map[row].each_index do |column|
				distance = hamming_distance_64(map[row][column], input)
				next if distance >= smallest_distance
				closest = {:row => row, :column => column}
				smallest_distance = distance
			end
		end
		data_points << {:x => closest[:column], :y => closest[:row]}
		radius_of_effect.times do |radius|
			rings[radius].each do |neighbor|
				neighbor_x = closest[:column] + neighbor[:x]
				neighbor_y = closest[:row] + neighbor[:y]
				next if (neighbor_y < 0 || neighbor_x < 0 || neighbor_y >= rows || neighbor_x >= columns)
				distance = hamming_distance_64(map[neighbor_y][neighbor_x], input)
				path = hamming_path(map[neighbor_y][neighbor_x] ^ input)
				steps_to_adjust = path.count * Math.exp(- (radius**2)/eta(iteration))
#				puts "#{steps_to_adjust} vs #{path.count} at #{radius}"
				steps_to_adjust.to_i.times do |step_index|
					map[neighbor_y][neighbor_x] ^= path[step_index]
				end
			end
		end

	#	puts "#{closest.inspect} to #{input} is #{smallest_distance} -> [#{index}]"
		markers[closest[:row]][closest[:column]] = '0' if iteration == iterations - 1
		index+=1
#		puts "Input was #{input}"
	end
	p "Iteration #{iteration}"
	map.each_index do |row|
		map[row].each_index do |column|
			intensity = hamming_distance_64(map[row][column], 0) * 4
			f.pixel_color(column, row, "rgb(0,#{intensity},0)")
		end
	end
	data_points.each do |data_point|
		f.pixel_color(data_point[:x], data_point[:y], "rgb(255,0,0)")
	end
	animated_gif << f
	f.write("som/som#{iteration}.jpg")
end

animated_gif.write("composite_som.gif")


#data_points.each do |data_point|
#	f.pixel_color(data_point[:x], data_point[:y], "rgb(255,255,255)")
#end



