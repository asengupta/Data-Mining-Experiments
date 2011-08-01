require 'rubygems'
require 'activerecord'

ActiveRecord::Base.establish_connection(
  :adapter => "mysql",
  :host => "localhost",
  :database => "data_mining",
  :username => "root",
  :password => ""
)




