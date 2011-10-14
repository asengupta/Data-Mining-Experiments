handle = File.open('csv/Ang2010TestsModified.csv', 'r')

inputs = []
good_data = []
total_bad_data = 0
handle.each_line do |line|
	is_bad = false
	split_elements = line.split('|')
	puts line if split_elements.count != 122
	split_elements[8..63].each do |s|
		s = s.chomp
		is_bad = true if s == '' || !(s == '0' || s == '1')
	end
	split_elements[65..120].each do |s|
		s = s.chomp
		is_bad = true if s == '' || !(s == '0' || s == '1')
	end
	
	total_bad_data += 1 if is_bad
	pre_test_responses = split_elements[8..63].collect {|e| e.to_i}
	post_test_responses = split_elements[65..120].collect {|e| e.to_i}

	pre_total = 0
	pre_test_responses.each do |r|
		pre_total += 1 if r == 1
	end
	post_total = 0
	post_test_responses.each do |r|
		post_total += 1 if r == 1
	end
	
	puts line if (post_total - pre_total) < 0 || post_total == 0 || pre_total == 0
end

puts total_bad_data
puts good_data.count

