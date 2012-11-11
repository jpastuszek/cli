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

		class UsageError < ParsingError
		end
	end

	class Values < OpenStruct
		def value(argument, value)
			send((argument.name.to_s + '=').to_sym, value) 
		end

		def append(argument, value)
			v = (get(argument) or [])
			v << value
			send((argument.name.to_s + '=').to_sym, v) 
		end

		def set(argument)
			value(argument, true)
		end

		def get(argument)
			send(argument.name.to_s)
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

		raise ParserError::MultipleArgumentsSpecifierError.new(@arguments.multiary) if @arguments.multiary.length > 1
	end

	def switch(name, options = {})
		switch_dsl = DSL::Switch.new(name, options)
		check_switch_collision!(switch_dsl)
		@switches << switch_dsl
	end

	def option(name, options = {})
		option_dsl = DSL::Option.new(name, options)
		check_switch_collision!(option_dsl)
		@options << option_dsl
	end

	def options(name, options = {})
		option_dsl = DSL::Options.new(name, options)
		check_switch_collision!(option_dsl)
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
				values.version = "#{CLI.name} version \"#{@version}\"\n"
				return values
			end
		end

		# initialize values
		@options.each do |o|
			values.value(o, nil)
		end

		@switches.each do |o|
			values.value(o, nil)
		end

		# initialize multi options
		@options.multiary.each do |o|
			values.value(o, [])
		end

		# process switches
		mandatory_options = @options.mandatory.dup

		while not argv.first == '--' and Switches.is_switch?(argv.first)
			arg = argv.shift

			if switch = @switches.find(arg)
				values.set(switch)
			elsif option = @options.find(arg)
				value = argv.shift or raise ParsingError::MissingOptionValueError.new(option)
				if option.multiary?
					values.append(option, option.cast(value))
				else
					values.value(option, option.cast(value))
				end
				mandatory_options.delete(option)
			else
				raise ParsingError::UnknownSwitchError.new(arg) unless switch
			end
		end

		# set defaults
		@options.unarry.each do |o|
			next unless o.has_default?
			values.value(o, o.default_cast) if values.get(o) == nil
		end

		@options.multiary.each do |o|
			next unless o.has_default?
			values.value(o, o.default_cast) if values.get(o) == []
		end

		# check mandatory options
		raise ParsingError::MandatoryOptionsNotSpecifiedError.new(mandatory_options) unless mandatory_options.empty?

		argv.shift if argv.first == '--'

		# process arguments
		arguments = @arguments.dup
		while argument = arguments.shift
			value = if arguments.mandatory.length < argv.length
				arg = argv.shift

				if argument.multiary?
					v = [arg]
					while argv.length > arguments.length
						v << argv.shift
					end
					v
				else
					arg
				end
			else
				if argument.has_default?
					argument.default
				elsif not argument.mandatory?
					argument.multiary? ? [] : nil
				else
					raise ParsingError::MandatoryArgumentNotSpecifiedError.new(argument) if argv.empty?
				end
			end

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

			if block_given?
				begin
					yield pp
				rescue RuntimeError => e
					raise ParsingError::UsageError, e.message
				end
			end
			pp
		rescue ParsingError => pe
			usage!(pe, stderr)
		end
	end

	def self.name
		File.basename $0
	end

	def usage(msg = nil)
		out = StringIO.new
		out.puts msg if msg
		out.print "Usage: #{CLI.name}"
		out.print ' [switches|options]' if not @switches.empty? and not @options.optional.empty?
		out.print ' [switches]' if not @switches.empty? and @options.optional.empty?
		out.print ' [options]' if @switches.empty? and not @options.optional.empty?
		@options.mandatory.each do |o|
			out.print " #{o.switch} <value>"
		end
		out.print ' [--]' if not @arguments.empty? and (not @switches.empty? or not @options.empty?)
		out.print ' ' unless @arguments.empty?
		out.print(@arguments.map do |a|
			v = ''
			v += '[' unless a.mandatory?
			v += a.multiary? ? a.to_s + '*': a.to_s
			v += ']' unless a.mandatory?
			v
		end.join(' '))
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
				unless o.multiary?
					out.print "   #{o.switch}"
				else
					out.print "   #{o.switch}*"
				end
				out.print " (#{o.switch_short})" if o.has_short?
				out.print ' (mandatory)' if o.mandatory?
				if o.has_default_label?
					out.print " [#{o.default_label}]"
				elsif o.has_default?
					out.print " [%s]" % o.default
				end
				out.print " - #{o.description}" if o.description?
				out.puts
			end
		end

		unless @arguments.empty?
			out.puts "Arguments:"
			@arguments.each do |a|
				unless a.multiary?
					out.print "   #{a}"
				else
					out.print "   #{a}*"
				end
				out.print ' (optional)' if not a.mandatory? and not a.has_default?
				if a.has_default_label?
					out.print " [#{a.default_label}]"
				elsif a.has_default?
					out.print " [%s]" % (a.default.is_a?(Array) ? a.default.join(' ') : a.default)
				end
				out.print " - #{a.description}" if a.description?
				out.puts
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

	private

	def check_switch_collision!(switch_dsl)
		type = switch_dsl.class.name.downcase.sub(/.*::/, '')
		{
			'switch' => @switches, 
			'option' => @options
		}.each_pair do |collection_type, collection|
			what = (type == collection_type ? type : collection_type + ' and ' + type)

			raise ParserError::LongNameSpecifiedTwiceError.new(what, switch_dsl) if collection.has_long?(switch_dsl) 
			raise ParserError::ShortNameSpecifiedTwiceError.new(what, switch_dsl) if collection.has_short?(switch_dsl) 
		end
	end
end

