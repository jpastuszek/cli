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
					raise ParsingError::CastError.new(@name, @options[:cast].name, e)
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

		module Value
			def default
				@options[:default]
			end

			def has_default?
				@options.member? :default
			end

			def optional?
				has_default?
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

			def to_s
				name.to_s.tr('_', '-')
			end
		end

		class Switch < DSL::Base
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

			def optional?
				has_default? or not @options[:required]
			end
		end
	end
end

