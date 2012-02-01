class CLI::Arguments < Array
	def has?(argument_dsl)
		self.find{|a| a.name == argument_dsl.name}
	end

	def mandatory
		select{|a| a.mandatory?}
	end

	def multiary
		select{|a| a.multiary?}
	end
end

