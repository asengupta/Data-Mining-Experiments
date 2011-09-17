require 'rubygems'
require 'amqp'
#gem 'rabbitmq-jruby-client'
#require 'rabbitmq_client'

#EventMachine.run do
#  connection = AMQP.connect(:host => '127.0.0.1', :port => 5672)
#  puts "Connected to AMQP broker. Running #{AMQP::VERSION} version of the gem..."
##begin
#  channel = AMQP::Channel.new(connection)
#  queue = channel.queue('lambda', :auto_delete => true)
#  exchange = channel.direct('lambda_exchange')
#  queue.subscribe do |p|
#	puts "Lololo"
#	puts p
#  end
#  exchange.publish "Hahahahaha", :routing_key => queue.name
#rescue => e
#	puts e
#end
#  connection.close { EventMachine.stop }
#end
class MySketch < Processing::App
	def setup
		EventMachine.run do
			connection = AMQP.connect(:host => '127.0.0.1', :port => 5672)
		  	puts "Connected to AMQP broker. Running #{AMQP::VERSION} version of the gem..."
		  	channel = AMQP::Channel.new(connection)
		  	exchange = channel.direct('lambda_exchange', :auto_delete => true)
			queue = channel.queue('lambda', :auto_delete => false, :passive => true)
		  	queue.bind(exchange, :routing_key => 'lambda')
			queue.subscribe do |payload|
				puts "Received a message: #{payload}. Good..."
			end
		end
	end
end

