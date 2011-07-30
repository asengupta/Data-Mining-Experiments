require 'set'
require 'RMagick'

include Math
include Magick

handle = File.open('/home/avishek/BitwiseOperations/Ang2010TestsModified.csv', 'r')
inputs = []
dimensions = {:language => Set.new, :gender => Set.new, :area => Set.new}

samples = 28535
#samples = 500
i = 1
handle.each_line do |line|
	break if i > samples
	split_elements = line.split('|')
	pre_score = 0
	post_score = 0
	split_elements[8..63].each {|e| pre_score+= e.to_i}
	split_elements[65..120].each {|e| post_score+= e.to_i}
	record = {:language => split_elements[5], :gender => split_elements[4], :before => pre_score, :after => post_score, :id => split_elements[0], :area => split_elements[1]}
	dimensions[:language].add(record[:language])
	dimensions[:gender].add(record[:gender])
	dimensions[:area].add(record[:area])
	inputs << record
	i += 1
end

dimensions[:language] = dimensions[:language].to_a
dimensions[:gender] = dimensions[:gender].to_a
dimensions[:area] = dimensions[:area].to_a

axes = [:language, :gender, :area, :before, :after]

height = 1200
width = 1400
f = Image.new(width,height) { self.background_color = "black" }
gc = Magick::Draw.new
gc.stroke('red')
gc.stroke_width(1)

def x_scale(index, width, axes)
	index * width.to_f / axes.count
end


inputs.each do |input|
	last_x = last_y = 0
	axes.each_index do |axis_index|
		axis_x = x_scale(axis_index, width, axes)
		dimension_range = dimensions[axes[axis_index]]
		if (dimension_range != nil)
			scale = height.to_f / dimension_range.count
			y = dimension_range.index(input[axes[axis_index]]) * scale
		else
			y = input[axes[axis_index]] * height.to_f / 56
		end
#		p "(#{last_x},#{last_y}) -> (#{axis_x},#{y*5})"
		gc.line(last_x,last_y,axis_x,y)
		last_x = axis_x
		last_y = y
	end
end

gc.stroke('green')
axes.each_index do |axis_index|
	axis_x = x_scale(axis_index, width, axes)
	gc.line(axis_x, 0, axis_x, height)
end


gc.draw(f)
f.write("parallel_coordinates.jpg")

