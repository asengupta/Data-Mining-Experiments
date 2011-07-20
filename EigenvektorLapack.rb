require 'rubygems'
require 'numru/lapack'
include NumRu

def covariance(inputs, dimension_1, dimension_2)
	
	sum = 0
	inputs.each {|input| sum += input[dimension_1] * input[dimension_2]}
	sum / inputs.length
end

means = Array.new(56)
means.fill(0)

handle = File.open('/home/avishek/BitwiseOperations/Ang2010TestsModified.csv', 'r')
inputs = []
handle.each_line do |line|
	split_elements = line.split('|')
	pre_test_responses = split_elements[8..63].collect {|e| e.to_f}
	response_as_bits = []
	pre_test_responses.each do |r|
		response_as_bits << r
	end
	inputs << response_as_bits
end

samples = 20000
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

d.each {|v| p v}
p z

