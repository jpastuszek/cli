require 'cli/switches'

class CLI::Options < CLI::Switches
	def initialize
		super
		@defaults = []
		@mandatory = []
	end

	def <<(option_dsl)
		super option_dsl
		@defaults << option_dsl if option_dsl.has_default?
		@mandatory << option_dsl unless option_dsl.optional?
	end

	attr_reader :defaults
	attr_reader :mandatory
end

