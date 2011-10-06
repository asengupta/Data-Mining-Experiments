require 'rubygems'
Gem.clear_paths
ENV['GEM_HOME'] = '/home/avishek/jruby/jruby-1.6.4/lib/ruby/gems/1.8'
ENV['GEM_PATH'] = '/home/avishek/jruby/jruby-1.6.4/lib/ruby/gems/1.8'
require 'active_record'
require 'arjdbc'

ActiveRecord::Base.establish_connection(
  :adapter => "jdbcmysql",
  :host => "localhost",
  :database => "data_mining",
  :username => "root",
  :password => ""
)




