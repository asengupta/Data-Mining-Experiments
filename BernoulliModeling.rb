require 'rubygems'
require 'active_record'

#a = NArray[	[1,2,3,4,1],
#		[2,2,3,4,2],
#		[3,3,3,3,5],
#		[4,4,3,4,4],
#		[1,2,5,4,5]
#	   ]

#m1 = NMatrix.ref(a)
#m2 = NMatrix.ref(a)
#product = m1*m2
#puts product.inspect
#exit

ActiveRecord::Base.establish_connection(
  :adapter => "mysql2",
  :host => "localhost",
  :database => "data_mining",
  :username => "root",
  :password => ""
)

class Response < ActiveRecord::Base
end

responses = Response.find(:all)

def probabilities(responses, &metric)
	bins = Array.new(56)
	bins.fill(0)
	responses.each do |r|
		response_as_bits = []
		bit_string = metric.call(r).to_s(2).rjust(56, '0')
		bit_string.each_char {|c| response_as_bits << (c == '1'?1:0)}
		response_as_bits.each_index {|i| bins[i] = bins[i] + 1 if response_as_bits[i] == 1}
	end

	bins.collect {|b| b / responses.count.to_f}
end

pre = probabilities(responses) {|r| r[:pre_performance]}
post = probabilities(responses) {|r| r[:post_performance]}

i = 0
while i <= 56
	puts "#{i + 1} & #{pre[i]} & #{post[i]} \\\\"
	i += 1
end

