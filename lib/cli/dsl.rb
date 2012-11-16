class CLI
	module DSL
		class Base
			def initialize(name, options = {})
				class_name = self.class.name.gsub(/.*:/, '').downcase
				raise ParserError::NameArgumetNotSymbolError.new(class_name, name) unless name.is_a? Symbol
				raise ParserError::OptionsArgumentNotHashError.new(class_name, options) unless options.is_a? Hash
				@name = name
				@options = options
			end

			attr_reader :name
		end
		
		module Cast
			def cast(value)
				begin
					cast_to = @options[:cast] or return value

					if cast_to.is_a? Module # all classes are modules
						if cast_to == Integer
							Integer(value)
						elsif cast_to == Float
							Float(value)
						elsif cast_to.respond_to? :new
							cast_to.new(value)
						elsif cast_to.respond_to? :load
							cast_to.load(value)
						else
							raise ArgumentError, "can't cast to class or module #{cast_to.class.name}"
						end
					else
						if cast_to.is_a? Proc
							cast_to.call(value)
						else
							raise ArgumentError, "can't cast to instance of #{cast_to.class.name}"
						end
					end
				rescue => e
					raise ParsingError::CastError.new(@name, @options[:cast].respond_to?(:name) ? @options[:cast].name : @options[:cast], e)
				end
			end
		end

		module Description
			def description?
				@options.member? :description
			end

			def description
				@options[:description].to_s
			end
		end

		module Value
			def default
				@options[:default].to_s
			end

			def default_cast
				cast(default)
			end

			def has_default?
				@options.member? :default
			end

			def default_label
				@options[:default_label].to_s
			end

			def has_default_label?
				@options.member? :default_label
			end

			def mandatory?
				not has_default? and @options[:required]
			end
		end

		module MultiDefault
			def default
				value = @options[:default]
				value.is_a?(Array) ? value.map{|v| v.to_s} : [value.to_s]
			end

			def default_cast
				default.map{|d| cast(d)}
			end
		end

		class Input < DSL::Base
			include DSL::Cast
			include DSL::Description

			def to_s
				(@name or @options[:cast] or 'data').to_s.tr('_', '-')
			end
		end

		class Argument < DSL::Base
			include DSL::Value
			include DSL::Cast
			include DSL::Description

			def initialize(name, options = {})
				super
				@options[:required] = true unless @options.member?(:required)
			end

			def to_s
				name.to_s.tr('_', '-')
			end

			def multiary?
				false
			end
		end

		class Arguments < Argument
			include DSL::MultiDefault

			def cast(values)
				out = []
				values.each do |v|
					out << super(v)
				end
				out
			end

			def multiary?
				true
			end
		end

		class Switch < DSL::Base
			def initialize(name, options = {})
				super(name, options)
				if short = options[:short]
					raise ParserError::ShortNameNotSymbolError.new(self, short) if not short.is_a? Symbol
					raise ParserError::ShortNameIsInvalidError.new(self, short) if short.to_s.length > 1
				end
			end

			include DSL::Description

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

		class Option < Switch
			include DSL::Value
			include DSL::Cast

			def multiary?
				false
			end
		end

		class Options < Option
			include DSL::MultiDefault

			def multiary?
				true
			end
		end
	end
end

