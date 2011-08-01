require 'set'
require 'RMagick'

include Math
include Magick

handle = File.open('/home/avishek/BitwiseOperations/Ang2010TestsModified.csv', 'r')
inputs = []
dimensions = {:language => Set.new, :gender => Set.new, :area => Set.new}

samples = 28535
#samples = 5000
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

def x_scale(index, width, axes)
	index * width.to_f / axes.count
end


partitioned_inputs_by_area = {}
dimensions[:area].each do |area|
	partitioned_inputs_by_area[area] = inputs.select {|i| i[:area] == area}
end

partitioned_inputs_by_area.each do |area, input_set|
	f = Image.new(width,height) { self.background_color = "black" }
	gc = Magick::Draw.new
	gc.stroke('red')
	gc.stroke_width(1)
	input_set.each do |input|
		last_x = last_y = 0
		value = dimensions[:area].index(input[:area])
		hue_scale = 360.0/dimensions[:area].count
		gc.stroke("hsl(#{value*hue_scale},100,100)")
		axes.each_index do |axis_index|
			axis_x = x_scale(axis_index, width, axes)
			dimension_range = dimensions[axes[axis_index]]
			if (dimension_range != nil)
				scale = height.to_f / dimension_range.count
				y = dimension_range.index(input[axes[axis_index]]) * scale
			else
				y = input[axes[axis_index]] * height.to_f / 56
			end
			gc.line(last_x,last_y,axis_x,y)
			last_x = axis_x
			last_y = y
		end
	end

	gc.stroke('white')
	axes.each_index do |axis_index|
		axis_x = x_scale(axis_index, width, axes)
		gc.line(axis_x, 0, axis_x, height)
	end


	gc.draw(f)
	f.write("para/parallel_coordinates_#{area.sub(/\//,'')}.jpg")
end

