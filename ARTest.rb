require 'schema'
require 'BitwiseOperations'

include BitwiseOperations

response = Response.find(55093)
p response.inspect

