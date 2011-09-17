require 'rubygems'
gem 'activerecord', "=3.0.9"
require 'active_record'

ActiveRecord::Base.establish_connection(
  :adapter => "jdbcmysql",
  :host => "localhost",
  :database => "data_mining",
  :username => "root",
  :password => ""
)




