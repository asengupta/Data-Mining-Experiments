require 'db_config'
require 'BitwiseOperations'

include BitwiseOperations


class Response < ActiveRecord::Base
	def pre_score
		bitcount_64(pre_performance.to_i)
	end

	def post_score
		bitcount_64(post_performance.to_i)
	end
end

