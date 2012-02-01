require 'cli/switches'

class CLI::Options < CLI::Switches
	def mandatory
		select{|o| o.mandatory?}
	end

	def optional
		select{|o| not o.mandatory?}
	end

	def unarry
		select{|a| not a.multiary?}
	end

	def multiary
		select{|a| a.multiary?}
	end
end

