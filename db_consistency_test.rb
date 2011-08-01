require 'BitwiseOperations'
require 'mysql'

include BitwiseOperations

handle = File.open('/home/avishek/BitwiseOperations/Ang2010TestsModified.csv', 'r')
my = Mysql::new("localhost", "root", "", "data_mining")

inputs = []
handle.each_line do |line|
	split_elements = line.split('|')
	pre_test_responses = split_elements[8..63].collect {|e| e.to_i}
	post_test_responses = split_elements[65..120].collect {|e| e.to_i}
	pre_response = 0
	post_response = 0
	pre_test_responses.each do |r|
		pre_response+= r
	end
	post_test_responses.each do |r|
		post_response+= r
	end

	result = my.query("select pre_performance, post_performance from responses where student_id=#{split_elements[3].to_i}")
	result.each do |row|
		if (bitcount_64(row[0].to_i) == pre_response) 
			print "."
		else print "F(pre)"
		end
		if (bitcount_64(row[1].to_i) == post_response) 
			print "."
		else print "F(pre)"
		end
	end
end

