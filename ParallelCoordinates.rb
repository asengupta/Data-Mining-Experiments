require 'schema'
require 'set'
require 'ruby-processing'

include Math

class MySketch < Processing::App
	  def setup
		frame_rate(30)
		smooth
		background(0,0,0)

		responses = Response.find(:all)
		@height = 800
		@width = 1400
		@inputs = []
		@dimensions = {:language => Set.new, :gender => Set.new, :area => Set.new}

		responses.each do |r|
			record = {:language => r.language, :gender => r.gender, :before => r.pre_total, :after => r.post_total, :id => r.student_id, :area => r.area}
			@dimensions[:language].add(r.language)
			@dimensions[:gender].add(r.gender)
			@dimensions[:area].add(r.area)
			@inputs << record
			i += 1
		end

#		@inputs = @inputs.select {|i| i[:before] < 10 && (i[:after] - i[:before]).abs <= 5}

		@dimensions[:language] = @dimensions[:language].to_a
		@dimensions[:gender] = @dimensions[:gender].to_a
		@dimensions[:area] = @dimensions[:area].to_a

		@axes = [:language, :gender, :area, :before, :after]
	  end
	  
	  def draw
		color_mode(HSB, 360, 100, 100)
		@inputs.each do |input|
			last_x = last_y = 0
			value = @dimensions[:area].index(input[:area])
			hue_scale = 360.0/@dimensions[:area].count
			stroke(value*hue_scale,100,100)
			@axes.each_index do |axis_index|
				axis_x = x_scale(axis_index, @width, @axes)
				dimension_range = @dimensions[@axes[axis_index]]
				if (dimension_range != nil)
					scale = @height.to_f / dimension_range.count
					y = dimension_range.index(input[@axes[axis_index]]) * scale
				else
					y = @height - input[@axes[axis_index]] * @height.to_f / 56
				end
				line(last_x, last_y, axis_x, y)
				last_x = axis_x
				last_y = y
			end
		end

		color_mode(RGB, 1.0)
		stroke(1,1,1)
		@axes.each_index do |axis_index|
			axis_x = x_scale(axis_index, @width, @axes)
			line(axis_x, 0, axis_x, @height)
		end
	end

	def x_scale(index, width, axes)
		index * width.to_f / axes.count
	end
end


h = 800
w = 1400

MySketch.new(:title => "My Sketch", :width => w, :height => h)


