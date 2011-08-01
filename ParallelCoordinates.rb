require 'set'
require 'RMagick'
require 'schema'

include Math
include Magick

responses = Response.find(:all)

inputs = []
dimensions = {:language => Set.new, :gender => Set.new, :area => Set.new}

samples = 28535
#samples = 500
i = 1
responses.each do |r|
	break if i > samples
	record = {:language => r.language, :gender => r.gender, :before => r.pre_total, :after => r.post_total, :id => r.student_id, :area => r.area}
	dimensions[:language].add(r.language)
	dimensions[:gender].add(r.gender)
	dimensions[:area].add(r.area)
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
#		p "(#{last_x},#{last_y}) -> (#{axis_x},#{y*5})"
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
f.write("parallel_coordinates.jpg")

