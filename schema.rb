require 'db_config'

class Response < ActiveRecord::Base
	def improvement
		self[:post_total] - self[:pre_total]
	end
end

class School < ActiveRecord::Base
end

