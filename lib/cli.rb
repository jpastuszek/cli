require 'ostruct'
require 'stringio'
require 'yaml'

class CLI
	class ParsingError < ArgumentError
	end

	class Parsed < OpenStruct
		def set(argument, value)
			send((argument.name.to_s + '=').to_sym, argument.cast(value)) 
		end
	end

	module Options
		module Cast
			def cast(value)
				begin
					cast_class = @options[:cast]
					if cast_class == nil
						value
					elsif cast_class == Integer
						value.to_i
					elsif cast_class == Float
						value.to_f
					elsif cast_class == YAML
						YAML.load(value)
					else
						cast_class.new(value)
					end
				rescue => e
					raise ParsingError, "failed to cast: #{@name} to type: #{@options[:cast].name}: #{e}"
				end
			end
		end

		module Description
			def description?
				@options.member? :description
			end

			def description
				@options[:description]
			end
		end
	end

	class STDINHandling
		def initialize(name, options = {})
			@name = name
			@options = options
		end

		include Options::Cast
		include Options::Description

		def to_s
			(@name or @options[:cast] or 'data').to_s.tr('_', '-')
		end
	end

	class Argument
		def initialize(name, options = {})
			@name = name
			@options = {
				:cast => String
			}.merge(options)
		end

		attr_reader :name

		include Options::Cast
		include Options::Description

		def default
			@options[:default]
		end

		def has_default?
			@options.member? :default
		end

		def optional?
			has_default?
		end
		
		def to_s
			name.to_s.tr('_', '-')
		end
	end

	class Option < Argument
		def optional?
			has_default? or not @options[:required]
		end

		def has_short?
			@options.member? :short
		end

		def short
			@options[:short]
		end

		def switch
			'--' + name.to_s.tr('_', '-')
		end

		def switch_short
			'-' + short.to_s
		end

		def to_s
			switch
		end
	end

	def initialize(&block)
		#TODO: optoins should be in own class?
		@options = []
		@optoins_long = {}
		@optoins_short = {}
		@options_default = []
		@options_required = []
		@arguments = []
		instance_eval(&block) if block_given?
	end

	def description(desc)
		@description = desc
	end

	def stdin(name = nil, options = {})
		@stdin_handling = STDINHandling.new(name, options)
	end

	def argument(name, options = {})
		raise ArgumentError, "expected argument options of type Hash, got: #{options.class.name}" unless options.is_a? Hash
		@arguments << Argument.new(name, options)
	end

	def option(name, options = {})
		o = Option.new(name, options)
		@options << o
		@optoins_long[name] = o
		@optoins_short[o.short] = o if o.has_short?
		@options_default << o if o.has_default?
		@options_required << o unless o.optional?
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
		@options_default.each do |o|
			parsed.set(o, o.default)
		end

		# process switches
		options_required = @options_required.dup
		while argv.first =~ /^-/
			switch = argv.shift
			option = if switch =~ /^--/
				@optoins_long[switch.sub(/^--/, '').tr('-', '_').to_sym]
			else
				@optoins_short[switch.sub(/^-/, '').tr('-', '_').to_sym]
			end

			if option
				value = argv.shift or raise ParsingError, "missing option argument: #{option}"
				parsed.set(option, value)
				options_required.delete(option)
			else
				raise ParsingError, "unknonw switch: #{switch}"
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

			parsed.set(argument, value)
		end

		# process stdin
		parsed.stdin = @stdin_handling.cast(stdin) if @stdin_handling

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
		out.print ' [options]' unless @optoins_long.empty?
		out.print ' ' + @arguments.map{|a| a.to_s}.join(' ') unless @arguments.empty?
		out.print " < #{@stdin_handling}" if @stdin_handling

		out.puts
		out.puts @description if @description

		if @stdin_handling and @stdin_handling.description?
			out.puts "Input:"
			out.puts "   #{@stdin_handling} - #{@stdin_handling.description}"
		end

		unless @optoins_long.empty?
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

