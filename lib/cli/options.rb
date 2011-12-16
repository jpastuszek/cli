require 'cli/switches'

class CLI::Options < CLI::Switches
	def defaults
		select{|o| o.has_default?}
	end

	def mandatory
		select{|o| o.mandatory?}
	end
end

