require 'schema'
require 'set'
require 'ruby-processing'

include Math

class MySketch < Processing::App
	app = self
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
		end

#		@inputs = @inputs.select {|i| i[:before] < 5 && (i[:after] - i[:before]).abs <= 5}
		@inputs = @inputs[0..300]
		@dimensions[:language] = @dimensions[:language].to_a
		@dimensions[:gender] = @dimensions[:gender].to_a
		@dimensions[:area] = @dimensions[:area].to_a

		@axes = [:language, :gender, :area, :before, :after]
	  end
	  
	  def draw
		@inputs.each do |input|
			last_x = last_y = 0
			value = @dimensions[:area].index(input[:area])
			hue_scale = 360.0/@dimensions[:area].count
			stroke(value*hue_scale,100,100)
			lines = []
			@axes.each_index do |axis_index|
				axis_x = x_scale(axis_index, @width, @axes)
				dimension_range = @dimensions[@axes[axis_index]]
				if (dimension_range != nil)
					scale = @height.to_f / dimension_range.count
					y = dimension_range.index(input[@axes[axis_index]]) * scale
				else
					y = @height - input[@axes[axis_index]] * @height.to_f / 56
				end

				lines << {:from => {:x => last_x, :y => last_y}, :to => {:x => axis_x, :y => y}}
				last_x = axis_x
				last_y = y
			end
			Sample.new(lines, value*hue_scale, self).draw
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

	class Sample
		def initialize(lines, hue, parent)
			@lines = lines
			@hue = hue
		end

		def draw()
			show = false
#			color_mode(HSB, 360, 100, 100)
#			stroke(10,1,5,1)
			for l in @lines
				smaller_y = [l[:from][:y], l[:to][:y]].min
				larger_y = [l[:from][:y], l[:to][:y]].max
				next if !(mouseX>=l[:from][:x] && mouseX<=l[:to][:x] && mouseY>=smaller_y && mouseY<=larger_y)
				m = (l[:to][:y] - l[:from][:y]).to_f/(l[:to][:x] - l[:from][:x]).to_f
				next if (m*mouseX - mouseY + l[:from][:y] - m*l[:from][:x]).abs > 1.5
				show = true
#				color_mode(HSB, 360, 100, 100)
#				stroke(@hue,100,100,255)
				break
			end
			if show
				stroke(1,1,1,1)
				@lines.each do |l|
					line(l[:from][:x], l[:from][:y], l[:to][:x], l[:to][:y])
				end
			else
				stroke(0.15,0.15,0.15,0.1)
				@lines.each do |l|
					line(l[:from][:x], l[:from][:y], l[:to][:x], l[:to][:y])
				end
			end
		end
	end
end


h = 800
w = 1400

MySketch.new(:title => "My Sketch", :width => w, :height => h)


