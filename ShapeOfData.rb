require 'set'
require 'RMagick'
require 'schema'

include Magick
include BitwiseOperations

def distribution(bins, filename)
	f = Image.new(500, 500) { self.background_color = "black" }

	pen = Draw.new
	pen.stroke('red')
	pen.stroke_width(2)
	bins.each_index do |position|
		pen.line(position*6 + 1, 500, position * 6 + 1, 500 - 500 * bins[position] / 2000.0)
	end

	pen.draw(f)
	f.write(filename)
end

responses = Response.find(:all)	

pre_bins = []
post_bins = []

56.times {pre_bins << 0}
56.times {post_bins << 0}

56.times do |pre_score|
	pre_bins[pre_score] = responses.select {|r| r.pre_total == pre_score}.count
end
56.times do |post_score|
	post_bins[post_score] = responses.select {|r| r.post_total == post_score}.count
end



distribution(pre_bins, "pre.jpg")
distribution(post_bins, "post.jpg")

