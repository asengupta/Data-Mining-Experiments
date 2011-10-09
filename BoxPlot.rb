require 'rubygems'
Gem.clear_paths
ENV['GEM_HOME'] = '/home/avishek/jruby/jruby-1.6.4/lib/ruby/gems/1.8'
ENV['GEM_PATH'] = '/home/avishek/jruby/jruby-1.6.4/lib/ruby/gems/1.8'

require 'schema'
require 'basis_processing'

class MySketch < Processing::App
	app = self
	load_libraries :opengl
	include_package "processing.opengl"	
	def setup
		size(width, height, OPENGL)
		raise "Is done"
		@screen_height = 900
		@width = width
		@height = height
		no_loop
		smooth
		background(0,0,0)
		color_mode(RGB, 1.0)
		metric = lambda {|r| r[:pre_total]}

		responses = Response.find(:all)
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
		p "Q1 = #{q1}"
		p "Q2 = #{q2}"
		p "Q3 = #{q3}"
		
		@x_unit_vector = {:x => 1.0, :y => 0.0}
		@y_unit_vector = {:x => 0.0, :y => 1.0}
		@screen_transform = Transform.new({:x => 5.0, :y => -5.0}, {:x => @width/2, :y => @screen_height/2})
		x_range = ContinuousRange.new({:minimum => least_improvement, :maximum => most_improvement})
		y_range = ContinuousRange.new({:minimum => least_improvement, :maximum => most_improvement})
		@c = CoordinateSystem.standard(x_range, y_range, self)
		@screen = Screen.new(@screen_transform, self, @c)
	end
	
	def quartile(n)
		lambda {|inputs| nth_quartile(n, inputs)}
	end
	
	def nth_quartile(n, cdf)
		cdf.keys[cdf.keys.index {|k| (cdf[k] - (n/4.0)).abs < 0.05 }]
	end
end

h = 1000
w = 1400
MySketch.new(:title => "My Sketch", :width => w, :height => h)

