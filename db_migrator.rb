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
	pre_response_as_64 = 0
	post_response_as_64 = 0
	pre_test_responses.each do |r|
		pre_response_as_64+= 1 if r == 1
		pre_response_as_64 <<= 1
	end
	post_test_responses.each do |r|
		post_response_as_64+= 1 if r == 1
		post_response_as_64 <<= 1
	end
	input =   { 
			:student_id => split_elements[0], 
			:area => split_elements[1].gsub(/'/,''), 
		    	:before => pre_response_as_64, 
		    	:after => post_response_as_64, 
		    	:language => split_elements[5], 
		    	:gender => split_elements[4]
		  }
	query = "insert into responses (student_id, area, language, gender, pre_performance, post_performance) values (#{input[:student_id]}, '#{input[:area]}', '#{input[:language]}', '#{input[:gender]}', #{input[:before]}, #{input[:after]});"
	my.query(query)

end


