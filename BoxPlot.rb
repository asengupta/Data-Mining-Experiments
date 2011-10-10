require 'rubygems'
Gem.clear_paths
ENV['GEM_HOME'] = '/home/avishek/jruby/jruby-1.6.4/lib/ruby/gems/1.8'
ENV['GEM_PATH'] = '/home/avishek/jruby/jruby-1.6.4/lib/ruby/gems/1.8'

require 'schema'
require 'basis_processing'

class MySketch < Processing::App
	app = self
	def setup
		@screen_height = 900
		@width = width
		@height = height
		no_loop
		smooth
		background(0,0,0)
		color_mode(HSB, 1.0)
		metric = lambda {|r| r[:post_total]}

		responses = Response.find(:all)
		bins = {}
		responses.each do |r|
			bins[r[:language]] = [] if bins[r[:language]].nil?
			bins[r[:language]] << r
		end
		
		bins["ALL"] = responses
		p bins.keys.inspect
		bins.each_pair do |k,v|
			begin
				bins[k] = box(k, v, metric)
			rescue => e
				puts "Deleting #{k}...statistically insignificant"
				bins.delete(k)
			end
		end

#		box = {:minimum => 20, :maximum => 70, :q1 => 30, :q2 => 40, :q3 => 50}

		@x_unit_vector = {:x => 1.0, :y => 0.0}
		@y_unit_vector = {:x => 0.0, :y => 1.0}
		@screen_transform = Transform.new({:x => 5.0, :y => -10.0}, {:x => 100, :y => @screen_height})
		x_range = ContinuousRange.new({:minimum => 0.0, :maximum => 360.0})
		y_range = ContinuousRange.new({:minimum => 0.0, :maximum => 100.0})
		@c = CoordinateSystem.new(Axis.new(@x_unit_vector,x_range), Axis.new(@y_unit_vector,y_range), self, [[1,0],[0,1]])
		@screen = Screen.new(@screen_transform, self, @c)
		position = 10
		box_width = 20
		whisker_width = 10
		f = createFont("Georgia", 24, true)
		text_font(f,16)
		
		stroke_weight(1)
		stroke(0.7,0,0)
		@screen.draw_axes(10, 10, {:x => lambda {|p| ''}, :y => lambda {|p| p.to_i}})

		stroke(0.7,0.3,1)
		no_fill
		bins.each_pair do |k,v|
			@screen.at(v) do |o,s|
				s.in_basis do
					stroke_weight(0.2)
					rect(position - box_width/2, o[:q1], box_width, o[:q2] - o[:q1])
					rect(position - box_width/2, o[:q2], box_width, o[:q3] - o[:q2])
					line(position, o[:q3], position, o[:maximum])
					line(position, o[:q1], position, o[:minimum])
					line(position - whisker_width/2, o[:minimum], position + whisker_width/2, o[:minimum])
					line(position - whisker_width/2, o[:maximum], position + whisker_width/2, o[:maximum])
				end
			end

			@screen.at({:x => position, :y => v[:minimum]}) {|o,m,s| text(o[:y], m[:x] + 5, m[:y] + 14)}
			@screen.at({:x => position, :y => v[:maximum]}) {|o,m,s| text(o[:y], m[:x] + 5, m[:y] - 14)}
			@screen.at({:x => position, :y => v[:q1]}) {|o,m,s| text(o[:y], m[:x] + 5, m[:y] + 14)}
			@screen.at({:x => position, :y => v[:q2]}) {|o,m,s| text(o[:y], m[:x] + 5, m[:y] + 14)}
			@screen.at({:x => position, :y => v[:q3]}) {|o,m,s| text(o[:y], m[:x] + 5, m[:y] - 14)}
			@screen.at({:x => position, :y => -5}) {|o,m,s| text(k, m[:x] - 15, m[:y])}
			
			position += 25
		end
	end
	
	def box(k, responses, metric)
		cumulative_distribution = {}
		responses.each do |r|
			key = metric.call(r)
			cumulative_distribution[key] = cumulative_distribution[key].nil? ? 1 : cumulative_distribution[key] + 1
		end
		
		maximum = cumulative_distribution.keys.max
		minimum = cumulative_distribution.keys.min

		keys = cumulative_distribution.keys.sort
		
		keys.each_index do |index|
			cumulative_distribution[keys[index]] = cumulative_distribution[keys[index]] + cumulative_distribution[keys[index - 1]] if index > 0
		end

		cumulative_distribution.each_pair do |k,v|
			cumulative_distribution[k] = v/responses.count.to_f
		end
		
		q1 = quartile(1).call(cumulative_distribution)
		q2 = quartile(2).call(cumulative_distribution)
		q3 = quartile(3).call(cumulative_distribution)
		maximum = keys.max
		minimum = keys.min
		
		box = {:minimum => minimum, :maximum => maximum, :q1 => q1, :q2 => q2, :q3 => q3}
	end
	
	def quartile(n)
		lambda {|inputs| nth_quartile(n, inputs)}
	end
	
	def nth_quartile(n, cdf)
			cdf.keys[cdf.keys.index {|k| (cdf[k] - (n/4.0)).abs < 0.09 }]
	end
end

h = 1000
w = 1800
MySketch.new(:title => "My Sketch", :width => w, :height => h)

