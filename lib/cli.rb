require 'ostruct'
require 'stringio'

require 'cli/dsl'
require 'cli/arguments'
require 'cli/switches'
require 'cli/options'

class CLI
	class ParserError < ArgumentError
		class NameArgumetNotSymbolError < ParserError
			def initialize(type, arg)
				super("#{type} name has to be of type Symbol, got #{arg.class.name}")
			end
		end

		class OptionsArgumentNotHashError < ParserError
			def initialize(type, arg)
				super("#{type} options has to be of type Hash, got #{arg.class.name}")
			end
		end

		class ArgumentNameSpecifiedTwice < ParserError
			def initialize(arg)
				super("argument '#{arg}' specified twice")
			end
		end

		class LongNameSpecifiedTwiceError < ParserError
			def initialize(what, switch_dsl)
				super("#{what} #{switch_dsl.switch} specified twice")
			end
		end

		class ShortNameSpecifiedTwiceError < ParserError
			def initialize(what, switch_dsl)
				super("short #{what} #{switch_dsl.switch_short} specified twice")
			end
		end

		class ShortNameNotSymbolError < ParserError
			def initialize(switch_dsl, short)
				super("short name for #{switch_dsl.switch} has to be of type Symbol, got #{short.class.name}")
			end
		end

		class ShortNameIsInvalidError < ParserError
			def initialize(switch_dsl, short)
				super("short name for #{switch_dsl.switch} has to be one letter symbol, got #{short.inspect}")
			end
		end

		class MultipleArgumentsSpecifierError < ParserError
			def initialize(arguments_dsl)
				super("only one 'arguments' specifier can be used, got: #{arguments_dsl.join(', ')}")
			end
		end
	end

	class ParsingError < ArgumentError
		class MissingOptionValueError < ParsingError
			def initialize(option)
				super("missing value for option #{option.switch}")
			end
		end

		class UnknownSwitchError < ParsingError
			def initialize(arg)
				super("unknown switch #{arg}")
			end
		end

		class MandatoryOptionsNotSpecifiedError < ParsingError
			def initialize(options)
				super("mandatory options not specified: #{options.map{|o| o.switch}.sort.join(', ')}")
			end
		end

		class MandatoryArgumentNotSpecifiedError < ParsingError
			def initialize(arg)
				super("mandatory argument '#{arg}' not given")
			end
		end

		class CastError < ParsingError
			def initialize(arg, cast_name, error)
				super("failed to cast: '#{arg}' to type: #{cast_name}: #{error}")
			end
		end
	end

	class Values < OpenStruct
		def value(argument, value)
			send((argument.name.to_s + '=').to_sym, value) 
		end

		def set(argument)
			value(argument, true)
		end
	end

	def initialize(&block)
		@arguments = Arguments.new
		@switches = Switches.new
		@options = Options.new

		instance_eval(&block) if block_given?

		switch :help, :short => :h, :description => 'display this help message'
		switch :version, :description => 'display version string' if @version
	end

	def description(desc)
		@description = desc
	end

	def version(version)
		@version = version.to_s
	end

	def stdin(name = :data, options = {})
		@stdin = DSL::Input.new(name, options)
	end

	def argument(name, options = {})
		argument_dsl = DSL::Argument.new(name, options)

		raise ParserError::ArgumentNameSpecifiedTwice.new(argument_dsl.name) if @arguments.has?(argument_dsl)

		@arguments << argument_dsl
	end

	def arguments(name, options = {})
		arguments_dsl = DSL::Arguments.new(name, options)

		raise ParserError::ArgumentNameSpecifiedTwice.new(arguments_dsl.name) if @arguments.has?(arguments_dsl)

		@arguments << arguments_dsl

		raise ParserError::MultipleArgumentsSpecifierError.new(@arguments.multiple) if @arguments.multiple.length > 1
	end

	def switch(name, options = {})
		switch_dsl = DSL::Switch.new(name, options)

		raise ParserError::LongNameSpecifiedTwiceError.new('switch', switch_dsl) if @switches.has_long?(switch_dsl) 
		raise ParserError::LongNameSpecifiedTwiceError.new('option and switch', switch_dsl) if @options.has_long?(switch_dsl) 
		raise ParserError::ShortNameSpecifiedTwiceError.new('switch', switch_dsl) if @switches.has_short?(switch_dsl) 
		raise ParserError::ShortNameSpecifiedTwiceError.new('option and switch', switch_dsl) if @options.has_short?(switch_dsl) 

		@switches << switch_dsl
	end

	def option(name, options = {})
		option_dsl = DSL::Option.new(name, options)

		raise ParserError::LongNameSpecifiedTwiceError.new('option', option_dsl) if @options.has_long?(option_dsl) 
		raise ParserError::LongNameSpecifiedTwiceError.new('switch and option', option_dsl) if @switches.has_long?(option_dsl) 
		raise ParserError::ShortNameSpecifiedTwiceError.new('option', option_dsl) if @options.has_short?(option_dsl) 
		raise ParserError::ShortNameSpecifiedTwiceError.new('switch and option', option_dsl) if @switches.has_short?(option_dsl) 

		@options << option_dsl
	end

	def parse(_argv = ARGV, stdin = STDIN, stderr = STDERR)
		values = Values.new
		argv = _argv.dup

		# check help and version
		argv.each do |arg|
			break if arg == '--'

			if arg == '-h' or arg == '--help' 
				values.help = usage
				return values
			end

			if @version and arg == '--version' 
				values.version = "#{name} version \"#{@version}\"\n"
				return values
			end
		end

		# set defaults
		@options.defaults.each do |o|
			values.value(o, o.cast(o.default))
		end

		# process switches
		mandatory_options = @options.mandatory.dup

		while not argv.first == '--' and Switches.is_switch?(argv.first)
			arg = argv.shift

			if switch = @switches.find(arg)
				values.set(switch)
			elsif option = @options.find(arg)
				value = argv.shift or raise ParsingError::MissingOptionValueError.new(option)
				values.value(option, option.cast(value))
				mandatory_options.delete(option)
			else
				raise ParsingError::UnknownSwitchError.new(arg) unless switch
			end
		end

		argv.shift if argv.first == '--'

		# check mandatory options
		raise ParsingError::MandatoryOptionsNotSpecifiedError.new(mandatory_options) unless mandatory_options.empty?

		# process arguments
		arguments = @arguments.dup
		mandatory_arguments_left = @arguments.mandatory.length

		while argument = arguments.shift
			value = if argv.length == mandatory_arguments_left and not argument.mandatory?
				argument.default # use defaults for optional arguments
			else
				argv.shift or raise ParsingError::MandatoryArgumentNotSpecifiedError.new(argument)
			end

			if argument.multiple?
				value = [value] unless value.is_a? Array
				while argv.length > arguments.length
					value << argv.shift
				end
			end

			mandatory_arguments_left -= 1 if argument.mandatory?

			values.value(argument, argument.cast(value))
		end

		# process stdin
		values.stdin = @stdin.cast(stdin) if @stdin

		values
	end

	def parse!(argv = ARGV, stdin = STDIN, stderr = STDERR, stdout = STDOUT)
		begin
			pp = parse(argv, stdin, stderr)
			if pp.help
				stdout.write pp.help
				exit 0
			end
			if pp.version
				stdout.write pp.version
				exit 0
			end
			pp
		rescue ParsingError => pe
			usage!(pe, stderr)
		end
	end

	def name
		File.basename $0
	end

	def usage(msg = nil)
		out = StringIO.new
		out.puts msg if msg
		out.print "Usage: #{name}"
		out.print ' [switches|options]' if not @switches.empty? and not @options.empty?
		out.print ' [switches]' if not @switches.empty? and @options.empty?
		out.print ' [options]' if @switches.empty? and not @options.empty?
		out.print ' [--]' if not @arguments.empty? and (not @switches.empty? or not @options.empty?)
		out.print ' ' + @arguments.map{|a| a.to_s}.join(' ') unless @arguments.empty?
		out.print " < #{@stdin}" if @stdin

		out.puts
		out.puts @description if @description

		if @stdin and @stdin.description?
			out.puts "Input:"
			out.puts "   #{@stdin} - #{@stdin.description}"
		end

		unless @switches.empty?
			out.puts "Switches:"
			@switches.each do |s|
				out.print '   '
				out.print s.switch
				out.print " (#{s.switch_short})" if s.has_short?
				out.print " - #{s.description}" if s.description?
				out.puts
			end
		end

		unless @options.empty?
			out.puts "Options:"
			@options.each do |o|
				out.print '   '
				out.print o.switch
				out.print " (#{o.switch_short})" if o.has_short?
				out.print " [%s]" % o.default if o.has_default?
				out.print " - #{o.description}" if o.description?
				out.puts
			end
		end

		described_arguments = @arguments.select{|a| a.description?}
		unless described_arguments.empty?
			out.puts "Arguments:"
			described_arguments.each do |a|
				out.puts "   #{a} - #{a.description}"
			end
		end

		out.rewind
		out.read
	end

	def usage!(msg = nil, io = STDERR)
		msg = "Error: #{msg}" if msg
		io.write usage(msg)
		exit 42
	end
end

