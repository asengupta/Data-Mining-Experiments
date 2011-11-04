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

def fill_contingency(responses, tables)
	responses.each do |r|
		pre_bitstring = r[:pre_performance].to_s(2).rjust(56, '0')
		post_bitstring = r[:post_performance].to_s(2).rjust(56, '0')
		i = 0
		while i <= 55
			tables[i][:k0_0] = tables[i][:k0_0] + 1 if pre_bitstring[i] == '0' && post_bitstring[i] == '0'
			tables[i][:k0_1] = tables[i][:k0_1] + 1 if pre_bitstring[i] == '0' && post_bitstring[i] == '1'
			tables[i][:k1_0] = tables[i][:k1_0] + 1 if pre_bitstring[i] == '1' && post_bitstring[i] == '0'
			tables[i][:k1_1] = tables[i][:k1_1] + 1 if pre_bitstring[i] == '1' && post_bitstring[i] == '1'
			i += 1
		end
	end
end

responses = Response.find(:all)

contingency_tables = []
56.times {contingency_tables << {:k1_1 => 0, :k1_0 => 0, :k0_1 => 0, :k0_0 => 0}}

fill_contingency(responses, contingency_tables)

i = 1
contingency_tables.each do |table|
	before_1 = table[:k1_0] + table[:k1_1]
	before_0 = table[:k0_0] + table[:k0_1]
	after_1 = table[:k0_1] + table[:k1_1]
	after_0 = table[:k0_0] + table[:k1_0]

	b = table[:k1_0]
	c = table[:k0_1]
	mc_nemar_statistic = (((b-c).abs() -0.5)**2).to_f/(b+c)
	puts "#{i} & #{mc_nemar_statistic} \\\\"
	i += 1
end

