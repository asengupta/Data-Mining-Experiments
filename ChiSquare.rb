require 'rubygems'
require 'schema'


responses = Response.find(:all)
responses_by_area = {}

responses.each do |r|
	if (responses_by_area[r[:area]] == nil)
		responses_by_area[r[:area]] = [r]
	else
		responses_by_area[r[:area]] << r;
	end
end

class Improvement
	def initialize(description, &criterion)
		@description = description
		@criterion = criterion
	end

	def does_fit(response)
		@criterion.call(response[:post_total] - response[:pre_total])
	end
end

improvements =	[
	Improvement.new('DECLINE') {|d| d < 0},
	Improvement.new('NONE') {|d| d == 0},
	Improvement.new('MARGINAL') {|d| d > 0 && d <= 10},
	Improvement.new('REASONABLE') {|d| d > 10 && d <= 20},
	Improvement.new('MARKED') {|d| d > 20 && d <= 30},
	Improvement.new('SIGNIFICANT') {|d| d > 30 && d <= 40},
	Improvement.new('HUGE') {|d| d > 40}
		]

contingency_table = {}
responses_by_area.each_key do |k|
	contingency_table[k] = {}
	improvements.each do |i|
		selecteds = responses_by_area[k].select do |r|
			i.does_fit(r)
		end
		contingency_table[k][i] = { :observed => selecteds.count }
		at_least_one_nonzero = true if contingency_table[k][i][:observed] > 0
	end
end

per_row_totals = {}
per_column_totals = {}

responses_by_area.each_key do |area|
	per_row_total = 0
	improvements.each do |i|
		per_row_total += contingency_table[area][i][:observed]
	end
	per_row_totals[area] = per_row_total
end

improvements.each do |i|
	per_column_total = 0
	responses_by_area.each_key do |area|
		per_column_total += contingency_table[area][i][:observed]
	end
	per_column_totals[i] = per_column_total
end

chi_square_statistic = 0
responses_by_area.each_key do |area|
	improvements.each do |i|
		expected = per_row_totals[area] * per_column_totals[i] / responses.count.to_f
		chi_square_statistic += (((contingency_table[area][i][:observed] - expected).abs)**2).to_f/expected
	end
end

puts "Chi-Square statistic = #{chi_square_statistic}"
degrees_of_freedom  = (responses_by_area.keys.count - 1) * (improvements.count - 1)
puts "Degrees of freedom = #{degrees_of_freedom}"

