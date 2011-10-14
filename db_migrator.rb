require 'mysql'

handle = File.open('/home/avishek/Code/DataMiningExperiments/csv/Ang2010TestsModified.csv', 'r')
my = Mysql::new("localhost", "root", "", "data_mining")

#my.query('CREATE TABLE responses (student_id int(11) DEFAULT NULL, area char(50) DEFAULT NULL, pre_performance bigint(20) DEFAULT NULL, post_performance bigint(20) DEFAULT NULL, language char(50) DEFAULT NULL, gender char(20) DEFAULT NULL, pre_total int, post_total int, id int(11) NOT NULL AUTO_INCREMENT, PRIMARY KEY (`id`));')

inputs = []
handle.each_line do |line|
	is_bad = false
	split_elements = line.split('|')
		split_elements[8..63].each do |s|
		is_bad = true if s == '' || !(s == '0' || s == '1')
	end
	split_elements[65..120].each do |s|
		is_bad = true if s == '' || !(s == '0' || s == '1')
	end

	next if is_bad
	pre_test_responses = split_elements[8..63].collect {|e| e.to_i}
	post_test_responses = split_elements[65..120].collect {|e| e.to_i}
	pre_response_as_64 = 0
	post_response_as_64 = 0
	pre_total = 0
	post_total = 0

	pre_test_responses.each do |r|
		pre_response_as_64+= 1 if r == 1
		pre_response_as_64 <<= 1
		pre_total += 1 if r == 1
	end
	pre_response_as_64 >>= 1
	post_test_responses.each do |r|
		post_response_as_64+= 1 if r == 1
		post_response_as_64 <<= 1
		post_total += 1 if r == 1
	end
	post_response_as_64 >>= 1
	input =   { 
			:student_id => split_elements[3], 
			:area => split_elements[1].gsub(/'/,''), 
		    	:before => pre_response_as_64, 
		    	:after => post_response_as_64, 
		    	:language => split_elements[5], 
		    	:gender => split_elements[4],
			:pre_total => pre_total,
			:post_total => post_total
		  }
	query = "insert into responses (student_id, area, language, gender, pre_performance, post_performance, pre_total, post_total) values (#{input[:student_id]}, '#{input[:area]}', '#{input[:language]}', '#{input[:gender]}', #{input[:before]}, #{input[:after]}, #{input[:pre_total]}, #{input[:post_total]});"
	my.query(query)

end


