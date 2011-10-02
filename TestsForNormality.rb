require 'rubygems'
require 'numru/lapack'
require 'activerecord'
require 'lambda-queuer'

include NumRu

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
  :adapter => "mysql",
  :host => "localhost",
  :database => "data_mining",
  :username => "root",
  :password => ""
)

class Response < ActiveRecord::Base
	def improvement
		Math.log(self[:post_total] - self[:pre_total] + 57)
	end
end

def mu(samples, mean, order)
	sum = 0.0
	samples.each {|s| sum += (s.improvement - mean)**order}
	sum/samples.count
end

responses = Response.find(:all)

n = responses.count.to_f
mean = 0.0
responses.each {|r| mean += r.improvement}
mean /= responses.count

mu4 = mu(responses, mean, 4)
mu3 = mu(responses, mean, 3)
variance = mu(responses, mean, 2)
alpha3 = Math.sqrt(variance)**3
alpha4 = variance**2

s = mu3.to_f/alpha3
k = mu4.to_f/alpha4 - 3

jb = n/6 * (s**2 + 0.25 * (k-3)**2)
puts "n = #{n}"
puts "Skewness = #{s}"
puts "Kurtosis = #{k}"
puts "JB statistic = #{jb}"

