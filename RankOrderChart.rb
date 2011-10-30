require 'rubygems'
require 'active_record'

ActiveRecord::Base.establish_connection(
  :adapter => "mysql2",
  :host => "localhost",
  :database => "data_mining",
  :username => "root",
  :password => ""
)

class School < ActiveRecord::Base
end

class Response < ActiveRecord::Base
	belongs_to :school
end

clusters = {}

responses = Response.find(:all)
schools = School.find(:all)

n = 1
responses.each do |r|
	cluster = schools[schools.index {|s| s[:school_id] == r[:school_id]}][:cluster]
	clusters[cluster] = [] if clusters[cluster].nil?
	clusters[cluster] << r
	n += 1
end

sorted_clusters = clusters.keys.sort {|x,y| clusters[y].count <=> clusters[x].count}
cdf = 0

n=1
sorted_clusters.each do |c|
	fraction = clusters[c].count/responses.count.to_f
	cdf += fraction
	puts "#{n} & #{c} & #{fraction} & #{cdf} \\"
	n += 1
end

