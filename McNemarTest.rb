require 'rubygems'
require 'active_record'

ActiveRecord::Base.establish_connection(
  :adapter => "mysql2",
  :host => "localhost",
  :database => "data_mining",
  :username => "root",
  :password => ""
)

class Response < ActiveRecord::Base
end

class School < ActiveRecord::Base
end

def fill_contingency(responses, tables)
	responses.each do |r|
		pre_bitstring = r[:pre_performance].to_s(2).rjust(56, '0')
		post_bitstring = r[:post_performance].to_s(2).rjust(56, '0')
		i = 0
		while i <= 55
			tables[i][:d] = tables[i][:d] + 1 if pre_bitstring[i] == '0' && post_bitstring[i] == '0'
			tables[i][:c] = tables[i][:c] + 1 if pre_bitstring[i] == '0' && post_bitstring[i] == '1'
			tables[i][:b] = tables[i][:b] + 1 if pre_bitstring[i] == '1' && post_bitstring[i] == '0'
			tables[i][:a] = tables[i][:a] + 1 if pre_bitstring[i] == '1' && post_bitstring[i] == '1'
			i += 1
		end
	end
end

def mc_nemar(responses)
	contingency_tables = []
	56.times {contingency_tables << {:a => 0, :b => 0, :c => 0, :d => 0}}

	fill_contingency(responses, contingency_tables)

	statistics = []
	contingency_tables.each do |table|
		before_1 = table[:b] + table[:a]
		before_0 = table[:d] + table[:c]
		after_1 = table[:c] + table[:a]
		after_0 = table[:d] + table[:b]

		b = table[:b]
		c = table[:c]
		mc_nemar_statistic = (((b-c).abs() -0.5)**2).to_f/(b+c)
		statistics << ((b+c < 25)? -1 : mc_nemar_statistic)
	end
	statistics
end

schools = School.find(:all)
responses = Response.find(:all)

clusters = {}
responses.each do |r|
	cluster = schools[schools.index {|s| s[:school_name] == r[:area]}][:cluster]
	clusters[cluster] = [] if clusters[cluster].nil?
	clusters[cluster] << r
end

cluster_statistics = {}
clusters.each_pair do |cluster, responses|
	cluster_statistics[cluster] = mc_nemar(responses)
end

puts cluster_statistics.inspect

