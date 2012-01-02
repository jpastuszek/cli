require 'cli/switches'

class CLI::Options < CLI::Switches
	def defaults
		select{|o| o.has_default?}
	end

	def mandatory
		select{|o| o.mandatory?}
	end

	def optional
		select{|o| not o.mandatory?}
	end

	def multiple
		select{|a| a.multiple?}
	end
end

