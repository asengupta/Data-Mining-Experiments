require 'set'
require 'rubygems'
require 'active_record'
include Math

ActiveRecord::Base.establish_connection(
  :adapter => "mysql2",
  :host => "localhost",
  :database => "data_mining",
  :username => "root",
  :password => ""
)

class Response < ActiveRecord::Base
	def improvement
		self[:post_total] - self[:pre_total]
	end
end

responses = Response.find(:all)


def improvement_category(r)
	return "BETTER_THAN_NOTHING" if r[:before] == 0 && r[:after] > r[:before]
	improvement = (r[:after] - r[:before]).to_f/r[:before].to_f
	return "EXCELLENT" if improvement >= 1
	return "GOOD" if improvement >= 0.4
	return "AVERAGE" if improvement >= 0.25
	return "SLIGHT" if improvement >= 0.15
	return "NO" if improvement >= 0.0
	"DECLINE"
end

def performance(score)
	return "EXCELLENT" if score >= 50
	return "GOOD" if score >= 40
	return "AVERAGE" if score >= 30
	return "REASONABLE" if score >= 20
	return "SLIGHT" if score >= 10
	"BAD"
end

def information_gain(attribute_to_predict, given_attribute, records, attribute_ranges)
	x = given_attribute
	y = attribute_to_predict
	range_for_given_attribute = attribute_ranges[x]
	range_for_attribute_to_predict = attribute_ranges[y]
	h_y_x = 0
	range_for_given_attribute.each do |x_value|
		h_y_x_v = 0
		records_matching_attribute_value = records.select {|r| r[x] == x_value}
		range_for_attribute_to_predict.each do |y_value|
			p_y_x_v = records_matching_attribute_value.select {|r| r[y] == y_value}.count.to_f/records_matching_attribute_value.count.to_f
			h_y_x_v+= - p_y_x_v * log(p_y_x_v) / log(2) if p_y_x_v > 0
		end
		p_x_v = records_matching_attribute_value.count.to_f / records.count.to_f
		h_y_x += h_y_x_v * p_x_v
	end
	h_y = 0
	range_for_attribute_to_predict.each do |y_value|
		p_y_v = records.select {|r| r[y] == y_value}.count.to_f/records.count.to_f
		h_y += - p_y_v * log(p_y_v) / log(2) if p_y_v > 0
	end

	h_y - h_y_x
end

#handle = File.open('/home/avishek/BitwiseOperations/Ang2010TestsModified.csv', 'r')
inputs = []
dimension_keys = [:language, :gender, :pre_performance, :area]
dimensions = {:language => Set.new, :gender => Set.new, :area => Set.new, :pre_performance => Set.new, :improvement => Set.new}
languages = Set.new

samples = 500
i = 1
responses.each do |r|
#	break if i > samples
	record = {:language => r[:language], :gender => r[:gender], :before => r[:pre_total], :after => r[:post_total], :id => r[:school_id], :area => r[:area]}
	record[:improvement] = improvement_category(record)
	record[:pre_performance] = performance(record[:before])
	dimensions[:language].add(record[:language])
	dimensions[:gender].add(record[:gender])
	dimensions[:area].add(record[:area])
	dimensions[:pre_performance].add(record[:pre_performance])
	dimensions[:improvement].add(record[:improvement])
	inputs << record
	i += 1
end


#inputs = inputs[0..(samples-1)]

puts information_gain(:improvement, :area, inputs, dimensions)
puts information_gain(:improvement, :gender, inputs, dimensions)
puts information_gain(:improvement, :language, inputs, dimensions)
puts information_gain(:improvement, :pre_performance, inputs, dimensions)

class DecisionNode
	attr_accessor :attribute, :range_bin, :records, :is_leaf, :prediction, :nodes
	def initialize
		@is_leaf = false
		@nodes = []
	end


	def describe(level)
		return if @prediction == "FAILURE"
		puts "\\> "*level + "#{@attribute} - #{@range_bin} #{("Prediction = " + @prediction) if @is_leaf} \\"
		@nodes.each {|n| n.describe(level + 1)}
	end
end

def build(root, current_dimensions, attribute_to_predict, dimension_ranges)
	if (root.records.empty?)
		root.prediction = "FAILURE"
		root.is_leaf = true
		return
	end
	if (current_dimensions.empty?)
		dominant_prediction_value = "lol"
		largest_count = 0
		dimension_ranges[attribute_to_predict].each do |v|
			records_valued_v = root.records.select {|r| r[attribute_to_predict] == v}
			if largest_count < records_valued_v.count
				largest_count = records_valued_v.count
				dominant_prediction_value = v
			end
		end
		
		root.prediction = dominant_prediction_value
		root.is_leaf = true
		return
	end
	range_of_values_for_prediction_attribute = Set.new
	root.records.each {|r| range_of_values_for_prediction_attribute.add(r[attribute_to_predict])}
	if (range_of_values_for_prediction_attribute.count == 1)
		root.is_leaf = true
		root.prediction = range_of_values_for_prediction_attribute.to_a.first
		return
	end
	current_dimensions.sort!{|x,y| information_gain(:improvement, x, root.records, dimension_ranges) <=> information_gain(:improvement, y, root.records, dimension_ranges)}
	maximally_independent_attribute = current_dimensions.last
	range_of_maximally_independent_attribute = dimension_ranges[maximally_independent_attribute]

	range_of_maximally_independent_attribute.each do |miav|
		branch = DecisionNode.new
		branch.attribute = maximally_independent_attribute
		branch.records = root.records.select {|r| r[maximally_independent_attribute] == miav}
		branch.range_bin = miav
		build(branch, current_dimensions[0..-2], attribute_to_predict, dimension_ranges)
		root.nodes << branch
	end
end

root = DecisionNode.new
root.records = inputs

build(root, dimension_keys, :improvement, dimensions)
root.describe(0)

