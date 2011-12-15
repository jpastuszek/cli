class CLI::Switches < Array
	def initialize
		@long = {}
		@short = {}
	end

	def <<(switch_dsl)
		super(switch_dsl)
		@long[switch_dsl.name] = switch_dsl
		@short[switch_dsl.short] = switch_dsl if switch_dsl.has_short?
	end

	def self.is_switch?(arg)
		arg =~ /^-/
	end

	def find(arg)
		if arg =~ /^--/
			find_long(arg)
		else
			find_short(arg)
		end
	end

	def find_long(arg)
		@long[arg.sub(/^--/, '').tr('-', '_').to_sym]
	end

	def find_short(arg)
		@short[arg.sub(/^-/, '').tr('-', '_').to_sym]
	end

	def has_long?(switch_dsl)
		@long.member?(switch_dsl.name)
	end

	def has_short?(switch_dsl)
		@short.member?(switch_dsl.short) if switch_dsl.has_short?
	end
end

