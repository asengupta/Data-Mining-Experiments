require 'rubygems'
Gem.clear_paths

#ENV['GEM_HOME'] = '/usr/lib/ruby/gems/1.8/gems/ruby-processing-1.0.9/lib/core/jruby-complete.jar!/META-INF/jruby.home/lib/ruby/gems/1.8'
#ENV['GEM_PATH'] = '/usr/lib/ruby/gems/1.8/gems/ruby-processing-1.0.9/lib/core/jruby-complete.jar!/META-INF/jruby.home/lib/ruby/gems/1.8'
ENV['GEM_HOME'] = '/home/avishek/jruby/jruby-1.6.3/lib/ruby/gems/1.8'
ENV['GEM_PATH'] = '/home/avishek/jruby/jruby-1.6.3/lib/ruby/gems/1.8'
puts ENV['GEM_HOME']
puts ENV['GEM_PATH']
require 'amqp'

class MySketch < Processing::App
	def setup
		EventMachine.run do
			connection = AMQP.connect(:host => '127.0.0.1', :port => 5672)
		  	puts "Connected to AMQP broker. Running #{AMQP::VERSION} version of the gem..."
		  	channel = AMQP::Channel.new(connection)
		  	exchange = channel.direct('lambda_exchange', :auto_delete => true)
			queue = channel.queue('lambda', :auto_delete => false, :passive => false)
		  	queue.bind(exchange, :routing_key => 'lambda')
			queue.subscribe do |payload|
				l = eval(payload)
				puts l.call([1,2,3,4,5,6,7,8])
				puts "Received a message: #{payload}. Good..."
			end
		end
	end
end

