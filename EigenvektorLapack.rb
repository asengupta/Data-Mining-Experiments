require 'rubygems'
require 'numru/lapack'
require 'activerecord'
require 'lambda-queuer'

include NumRu

qr = LambdaQueuer.new(:exchange => 'number', :request_routing_key => 'number_request')

ActiveRecord::Base.establish_connection(
  :adapter => "mysql",
  :host => "localhost",
  :database => "data_mining",
  :username => "root",
  :password => ""
)

class Response < ActiveRecord::Base
end

def covariance(inputs, dimension_1, dimension_2)

	sum = 0
	inputs.each {|input| sum += input[dimension_1] * input[dimension_2]}
	sum / inputs.length
end

responses = Response.find(:all)

means = Array.new(56)
means.fill(0)

inputs = []
responses.each do |r|
	bit_string = r[:pre_performance].to_s(2).rjust(56, '0')
	response_as_bits = []
	p "#{r[:student_id]} = #{r[:pre_performance].to_s(2).rjust(56, '0')}" if r[:pre_performance].to_s(2).length > 56
	bit_string.each_char do |bit|
		response_as_bits << (bit == '1'?1.0:0.0)
	end
	inputs << response_as_bits
end

samples = inputs.count
inputs = inputs[1..samples]
inputs.each do |input|
	56.times do |i|
		means[i] += input[i]
	end
end

means = means.collect {|t| t/samples}

inputs.each do |input|
	56.times do |i|
		input[i] -= means[i]
	end
end

covariance_matrix = []

56.times do |row|
	matrix_row = []
	56.times do |column|
		matrix_row << covariance(inputs, row, column)
	end
	covariance_matrix << matrix_row
end


uplo = "U"
a = NArray.to_na(covariance_matrix)
#a = NArray[	[1,2,3,4,1],
#		[2,2,3,4,2],
#		[3,3,3,3,5],
#		[4,4,3,4,4],
#		[1,2,5,4,5]
#	   ]

d, e, tau, work, info, a = NumRu::Lapack.ssytrd( uplo, a, 50)


info, d, e, z = NumRu::Lapack.ssteqr('I', d, e, a)

vektor = z.to_a.last
reduced = inputs.collect do |i|
	transformed = 0
	i.each_index do |score_index|
		p "[#{score_index}] = #{vektor[score_index]}" if vektor[score_index] == nil
		transformed += i[score_index] * vektor[score_index]
	end
	transformed
end

reduced.each {|r| p r}

