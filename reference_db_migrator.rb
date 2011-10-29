require 'mysql2'

handle = File.open('/home/avishek/Code/DataMiningExperiments/csv/ang_master.csv', 'r')
my = Mysql2::Client.new(:host => "localhost", :username => "root", :database => "data_mining")

#my.query('CREATE TABLE master (district char(50) DEFAULT NULL, block char(50) DEFAULT NULL, cluster char(50) DEFAULT NULL, school_id int, school_code char(20) DEFAULT NULL, school_name char(50) DEFAULT NULL, id int(11) NOT NULL AUTO_INCREMENT, PRIMARY KEY (`id`));')

inputs = []
handle.each_line do |line|
	is_bad = false
	split_elements = line.split(',')
	split_elements = split_elements.collect {|e| e.gsub(/'/, '').gsub(/"/, '').gsub(/\n/, '')}
	input =   { 
			:district => split_elements[0], 
			:block => split_elements[1], 
		    	:cluster => split_elements[2], 
		    	:school_id => split_elements[3].to_i, 
		    	:school_code => split_elements[4],
		    	:school_name => split_elements[6]
		  }
	puts input
	query = "insert into master (district, block, cluster, school_id, school_code, school_name) values ('#{input[:district]}', '#{input[:block]}', '#{input[:cluster]}', '#{input[:school_id]}', '#{input[:school_code]}', '#{input[:school_name]}');"
	puts query
	my.query(query)

end


