require 'cli/switches'

class CLI::Options < CLI::Switches
	def initialize
		super
		@defaults = []
		@required = []
	end

	def <<(option_dsl)
		super option_dsl
		@defaults << option_dsl if option_dsl.has_default?
		@required << option_dsl unless option_dsl.optional?
	end

	attr_reader :defaults
	attr_reader :required
end

