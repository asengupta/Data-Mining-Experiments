require 'set'
require 'BitwiseOperations'
require 'RMagick'

include Magick
include BitwiseOperations

handle = File.open('/home/avishek/BitwiseOperations/Ang2010TestsModified.csv', 'r')
inputs = []
handle.each_line do |line|
	split_elements = line.split('|')
	pre_test_responses = split_elements[8..56].collect {|e| e.to_i}
	response_as_64 = 0
	pre_test_responses.each do |r|
		response_as_64+= 1 if r == 1
		response_as_64 <<= 1
	end
	inputs << { :area => split_elements[0], :vector => response_as_64}
end

probabilities = {}
56.times {|position| probabilities[position] = 0}

inputs.each do |input|
	56.times do |position|
		probabilities[position] = probabilities[position] + 1 if (input[:vector] & (2**position)) == (2**position)
	end
end

56.times do |position|
	probabilities[position] = probabilities[position].to_f / inputs.count
end

f = Image.new(500, 500) { self.background_color = "black" }

pen = Draw.new
pen.stroke('red')
pen.stroke_width(2)
p probabilities.inspect
56.times do |position|
#	p probabilities.inspect
	pen.line(position*6 + 1, 500, position * 6 + 1, 500 - probabilities[position] * 500)
end

pen.draw(f)
f.write("pre_distribution.jpg")

