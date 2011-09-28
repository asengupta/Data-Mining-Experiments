# For area vs. improvement
# Chi-Square statistic = 56499.4692602837
# X2 = 9652.9739
# Degrees of freedom = 9426
# Null hypothesis rejected

# For area vs. pre-score
# Chi-Square statistic = 58665.7089390644
# X2 = 8062.2959
# Degrees of freedom = 7855
# Null hypothesis rejected

# For area vs. post-score
# Chi-Square statistic = 38567.0016158761
# X2 = 8062.2959
# Degrees of freedom = 7855
# Null hypothesis rejected

# For language vs. post-score
# Chi-Square statistic = 280.234448946825
# X2 = 96.2166
# Degrees of freedom = 75
# Null hypothesis rejected

# For language vs. improvement
# Chi-Square statistic = 232.464548410971
# X2 = 113.1452
# Degrees of freedom = 90
# Null hypothesis rejected

# For language vs. pre-score
# Chi-Square statistic = 277.85501653079
# X2 = 96.2166
# Degrees of freedom = 75
# Null hypothesis rejected

require 'rubygems'
require 'schema'

responses = Response.find(:all)
responses_by_language = {}

responses.each do |r|
	if (responses_by_language[r[:language]] == nil)
		responses_by_language[r[:language]] = [r]
	else
		responses_by_language[r[:language]] << r;
	end
end

class Improvement
	def initialize(description, &criterion)
		@description = description
		@criterion = criterion
	end

	def does_fit(response)
		@criterion.call(response[:pre_total])
	end
end

improvements =	[
	Improvement.new('NONE') {|d| d == 0},
	Improvement.new('MARGINAL') {|d| d > 0 && d <= 10},
	Improvement.new('REASONABLE') {|d| d > 10 && d <= 20},
	Improvement.new('MARKED') {|d| d > 20 && d <= 30},
	Improvement.new('SIGNIFICANT') {|d| d > 30 && d <= 40},
	Improvement.new('HUGE') {|d| d > 40}
		]

contingency_table = {}
responses_by_language.each_key do |k|
	contingency_table[k] = {}
	improvements.each do |i|
		selecteds = responses_by_language[k].select do |r|
			i.does_fit(r)
		end
		contingency_table[k][i] = { :observed => selecteds.count }
		at_least_one_nonzero = true if contingency_table[k][i][:observed] > 0
	end
end

per_row_totals = {}
per_column_totals = {}

responses_by_language.each_key do |language|
	per_row_total = 0
	improvements.each do |i|
		per_row_total += contingency_table[language][i][:observed]
	end
	per_row_totals[language] = per_row_total
end

improvements.each do |i|
	per_column_total = 0
	responses_by_language.each_key do |language|
		per_column_total += contingency_table[language][i][:observed]
	end
	per_column_totals[i] = per_column_total
end

chi_square_statistic = 0
responses_by_language.each_key do |language|
	improvements.each do |i|
		expected = per_row_totals[language] * per_column_totals[i] / responses.count.to_f
		chi_square_statistic += (((contingency_table[language][i][:observed] - expected).abs)**2).to_f/expected
	end
end

puts "Chi-Square statistic = #{chi_square_statistic}"
degrees_of_freedom  = (responses_by_language.keys.count - 1) * (improvements.count - 1)
puts "Degrees of freedom = #{degrees_of_freedom}"

