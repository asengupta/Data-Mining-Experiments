require 'rubygems'
Gem.clear_paths
ENV['GEM_HOME'] = '/home/avishek/jruby/jruby-1.6.4/lib/ruby/gems/1.8'
ENV['GEM_PATH'] = '/home/avishek/jruby/jruby-1.6.4/lib/ruby/gems/1.8'

require 'schema'
require 'basis_processing'
require 'distributions'

class MySketch < Processing::App
	def setup
		@highlight_block = ->(o,m,s) do
			rect_mode(CENTER)
			no_fill
			stroke(0.5,1,1)
			rect(m[:x], m[:y], 50, 50)
			text("#{o[:cluster]}", m[:x] + 5, m[:y] + 5)
		end
		@screen_height = 900
		@width = width
		@height = height
		@screen_transform = Transform.new({:x => 2000.0, :y => -2000.0}, {:x => 450, :y => 800})
		smooth
		no_loop
		background(0,0,0)
		color_mode(HSB, 1.0)

		all_responses = Response.find(:all)
		schools = School.find(:all)
		bins = {}
		all_responses.each do |r|
			bins[r[:school_id]] = [] if bins[r[:school_id]].nil?
			bins[r[:school_id]] << r
		end

		@c = CoordinateSystem.standard({:minimum => -2, :maximum => 2}, {:minimum => -2, :maximum => 2}, self)
		@screen = Screen.new(@screen_transform, self, @c)
		rect_mode(CENTER)
		randomiser = -> {(rand(100)-50)/2.0}
		already_written = {}
		bins.each_pair do |bin,responses|
			puts "Plotting for #{bin}"
			index = schools.index {|s| s[:school_id] == bin}
			school = schools[index]
			scaled_brilliance = responses.count/50.0
			fill(0.3,0.5,scaled_brilliance)
			stroke(0.3,0.5,scaled_brilliance)
			@screen.plot({:x => school[:latitude] - 12.8, :y => school[:longitude] - 77.4, :cluster => school[:cluster]}, :track => true) {|o,m,s|}
			@screen.plot({:x => school[:latitude] - 12.8, :y => school[:longitude] - 77.4, :value => responses.count.to_f/all_responses.count, :name => school[:school_name]}) do |o,m,s|
				ellipse(m[:x] + randomiser.call, m[:y] + randomiser.call, 2, 2)
				rect_mode(CENTER)
				stroke(0.1,0.5,0.3)
				no_fill()
				rect(m[:x], m[:y], 50, 50)
				fill(0.1,0.5,1)
#				text("#{school[:cluster]}", m[:x] + randomiser.call, m[:y] + randomiser.call) if already_written[school[:cluster]].nil?
				ellipse(m[:x] + 30, m[:y] + randomiser.call, 4, 4) if already_written[school[:cluster]].nil?
				already_written[school[:cluster]] = true
			end
		end
		stroke(0.1,0.5,1)
		fill(0.1,0.5,1)
		@screen.draw_axes(0.1,0.1)
	end

	def draw
	end
end

w = 1500
h = 1000

MySketch.send :include, Interactive
MySketch.new(:title => "My Sketch", :width => w, :height => h)


