require 'rubygems'
Gem.clear_paths
ENV['GEM_HOME'] = '/home/avishek/jruby/jruby-1.6.4/lib/ruby/gems/1.8'
ENV['GEM_PATH'] = '/home/avishek/jruby/jruby-1.6.4/lib/ruby/gems/1.8'

require 'schema'
require 'basis_processing'
require 'distributions'

class MySketch < Processing::App
	app = self
	
	def setup
		@highlight_block = ->(o,m,s) do
			rect_mode(CENTER)
			rect(m[:x], m[:y], 8, 8)
			text("(#{o[:x]}, #{o[:y]}) -> #{o[:value]}", m[:x] + 5, m[:y] + 5)
		end
		@screen_height = 900
		@width = width
		@height = height
#		@screen_transform = Transform.new({:x => 18.0, :y => -7500.0}, {:x => 100.0, :y => @screen_height})
		@screen_transform = Transform.new({:x => 20.0, :y => -3.0}, {:x => 100, :y => @screen_height})
		smooth
		no_loop
		background(0,0,0)
		color_mode(HSB, 1.0)

		responses = Response.find(:all)

		@c = CoordinateSystem.standard({:minimum => 0, :maximum => 60}, {:minimum => 0.0, :maximum => 250.0}, self, {:x => 'Score', :y => 'Probability'})
		@screen = Screen.new(@screen_transform, self, @c)

		
		clt(responses, ->(r) {r.improvement}, "Improvement", 0.2)
		@screen.draw_axes(10,10)
	end

	def clt(responses, metric, label, hue)
		mean = 0.0
		responses.each {|r| mean += metric.call(r)}
		puts "Raw mean=#{mean/responses.count}"
		means = []
		number_of_samplings = 1000
		sample_n = 500
		number_of_samplings.times do
			sum = 0
			sample_n.times do
				sum += metric.call(responses[rand(responses.count)]).to_f
			end
			means << sum.to_f/sample_n
		end
		stroke(hue,0.5,1)
		fill(hue,0.5,1)
		plot_distribution(means, ->(m) {m}, label)
		puts "JB statistic = #{jb_stats(means)}"
	end

	def jb_stats(responses)
		n = responses.count.to_f
		mean = 0.0
		responses.each {|r| mean += r}
		mean /= responses.count
		puts "CLT Mean=#{mean}"

		mu4 = mu(responses, mean, 4)
		mu3 = mu(responses, mean, 3)
		variance = mu(responses, mean, 2)
		alpha3 = Math.sqrt(variance)**3
		alpha4 = variance**2

		s = mu3.to_f/alpha3
		k = mu4.to_f/alpha4

		jb = n/6 * (s**2 + 0.25 * (k-3)**2)
#		puts "Variance = #{variance}"
#		puts "Skew = #{s}"
		jb
#		puts "n = #{n}"
#		puts "Skewness = #{s}"
#		puts "Kurtosis = #{k}"
#		puts "JB statistic = #{jb}"
	end

	def mu(samples, mean, order)
		sum = 0.0
		samples.each {|s| sum += (s - mean)**order}
		sum/samples.count
	end

	def plot_distribution(responses, metric, legend)
		bins = []
		max = responses.max
		min = responses.min
		
		start = min
		while start <= max
			bins << {:x => start, :from => start, :to => start + 0.2, :y => 0}
			start += 0.2
		end
		
		responses.each do |r|
			value = metric.call(r)
			bin_index = bins.index {|b| b[:from] <= value && b[:to] > value}
			bins[bin_index][:y] = bins[bin_index][:y] + 1
		end
		
		@screen.joined(false) do
			@screen.plot(bins, :legend => legend, :bar => true)
		end
	end
	
	def draw
	end
end

w = 1200
h = 1000

#MySketch.send :include, Interactive
MySketch.new(:title => "Shape of Score Data", :width => w, :height => h)


