require 'ostruct'
require 'stringio'
require 'yaml'

require 'cli/dsl'
require 'cli/switches'
require 'cli/options'

class CLI
	class ParsingError < ArgumentError
	end

	class Parsed < OpenStruct
		def value(argument, value)
			# TODO: no casting here
			send((argument.name.to_s + '=').to_sym, argument.cast(value)) 
		end

		def set(argument)
			send((argument.name.to_s + '=').to_sym, true) 
		end
	end

	def initialize(&block)
		@arguments = []
		@switches = Switches.new
		@options = Options.new
		instance_eval(&block) if block_given?
	end

	def description(desc)
		@description = desc
	end

	#TODO: type error handling (name, options)
	def stdin(name = nil, options = {})
		@stdin = DSL::Input.new(name, options)
	end

	def argument(name, options = {})
		@arguments << DSL::Argument.new(name, options)
	end

	def switch(name, options = {})
		@switches << DSL::Switch.new(name, options)
	end

	def option(name, options = {})
		@options << DSL::Option.new(name, options)
	end

	def parse(_argv = ARGV, stdin = STDIN, stderr = STDERR)
		parsed = Parsed.new

		argv = _argv.dup

		# check help
		if argv.include? '-h' or argv.include? '--help' 
			parsed.help = usage
			return parsed
		end

		# set defaults
		@options.defaults.each do |o|
			parsed.value(o, o.default)
		end

		# process switches
		options_required = @options.required.dup


		while Switches.is_switch?(argv.first)
			arg = argv.shift

			if switch = @switches.find(arg)
				parsed.set(switch)
			elsif option = @options.find(arg)
				#TODO: raise subclass of ParsingError
				value = argv.shift or raise ParsingError, "missing option argument: #{switch}"
				parsed.value(option, value)
				options_required.delete(option)
			else
				raise ParsingError, "unknonw switch: #{arg}" unless switch
			end
		end

		# check required
		raise ParsingError, "following options are required but were not specified: #{options_required.map{|o| o.switch}.join(', ')}" unless options_required.empty?

		# process arguments
		arguments = @arguments.dup
		while argument = arguments.shift
			value = if argv.length < arguments.length + 1 and argument.optional?
				argument.default # not enough arguments, try to skip optional if possible
			else
				argv.shift or raise ParsingError, "missing argument: #{argument}"
			end

			parsed.value(argument, value)
		end

		# process stdin
		parsed.stdin = @stdin.cast(stdin) if @stdin

		parsed
	end

	def parse!(argv = ARGV, stdin = STDIN, stderr = STDERR, stdout = STDOUT)
		begin
			pp = parse(argv, stdin, stderr)
			if pp.help
				stdout.write pp.help
				exit 0
			end
			pp
		rescue ParsingError => pe
			usage!(pe, stderr)
		end
	end

	def usage(msg = nil)
		out = StringIO.new
		out.puts msg if msg
		out.print "Usage: #{File.basename $0}"
		out.print ' [switches|options]' if not @switches.empty? and not @options.empty?
		out.print ' [switches]' if not @switches.empty? and @options.empty?
		out.print ' [options]' if @switches.empty? and not @options.empty?
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

