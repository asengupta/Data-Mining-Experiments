require 'rubygems'
require 'geokit'
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

Geokit::Geocoders::google = 'YOUR_GOOGLE_API_KEY'
schools = School.find(:all)
bins = {}
schools.each do |s|
	begin
		if bins[s[:cluster]].nil?
			puts "Geocoding for #{s[:cluster]}, Bangalore"
			sleep(2)
				result = Geokit::Geocoders::GoogleGeocoder.geocode("#{s[:cluster]}, Bangalore")
				bins[s[:cluster]] = result
		end
		s[:latitude] = bins[s[:cluster]].lat
		s[:longitude] = bins[s[:cluster]].lng
		s.save
	rescue => e
		puts "Barfed with \n #{e}"
	end
end

