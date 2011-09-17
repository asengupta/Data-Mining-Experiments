require 'rubygems'
require 'amqp'
require 'sourcify'

class LambdaQueuer
	def initialize(exchange, routing_key, host='127.0.0.1', port=5672)
		@host = host
		@port = port
		@exchange = exchange
		@routing_key = routing_key
	end

	def post(&block)
		EventMachine.run do
			begin
				connection = AMQP.connect(:host => @host, :port => @port)
				puts "Connected to AMQP broker. Running #{AMQP::VERSION} version of the gem..."
			  	channel = AMQP::Channel.new(connection)
			  	exchange = channel.direct(@exchange, :auto_delete => true)
			  	queue = channel.queue(@routing_key, :auto_delete => false, :passive => true)
			  	queue.bind(exchange, :routing_key => @routing_key)
				v = block.to_source
			  	exchange.publish(v, :routing_key => @routing_key)
				EventMachine.add_timer(2) do
					connection.close { EventMachine.stop }
				end
			rescue => e
				puts e
			end
		end
	end
end

LambdaQueuer.new('lambda_exchange', 'lambda').post {|all| all}

