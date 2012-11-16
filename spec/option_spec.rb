require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe CLI do
	describe 'option handling' do
		it "should handle long option names" do
			ps = CLI.new do
				option :location
			end.parse(['--location', 'singapore'])
			ps.location.should be_a String
			ps.location.should == 'singapore'
		end

		it "should handle short option names" do
			ps = CLI.new do
				option :location, :short => :l
			end.parse(['-l', 'singapore'])
			ps.location.should be_a String
			ps.location.should == 'singapore'
		end

		it "should support casting" do
			ps = CLI.new do
				option :size, :cast => Integer
			end.parse(['--size', '24'])
			ps.size.should be_a Integer
			ps.size.should == 24
		end

		it "casting should fail if not proper integer given" do
			lambda {
				ps = CLI.new do
					option :size, :cast => Integer
				end.parse(['--size', '24.99'])
			}.should raise_error(CLI::ParsingError::CastError)
		end

		it "casting should fail if not proper float given" do
			lambda {
				ps = CLI.new do
					option :size, :cast => Float
				end.parse(['--size', '24.99x'])
			}.should raise_error(CLI::ParsingError::CastError)
		end

		it "casting should fail if there is error in cast lambda" do
			lambda {
				ps = CLI.new do
					option :size, :cast => lambda{|v| fail 'test'}
				end.parse(['--size', '24.99x'])
			}.should raise_error(CLI::ParsingError::CastError)
		end

		it "should support casting of multiple options" do
			ps = CLI.new do
				options :size, :cast => Integer
			end.parse(['--size', '24', '--size', '10'])
			ps.size.should be_a Array
			ps.size.should == [24, 10]
		end

		it "should support casting of multiple options with default" do
			ps = CLI.new do
				options :log_file, :cast => Pathname, :default => 'test.log'
			end.parse(['--log-file', 'server.log', '--log-file', 'error.log'])

			ps.log_file.should be_a Array
			ps.log_file.length.should == 2

			ps.log_file.first.should be_a Pathname
			ps.log_file.first.to_s.should == 'server.log'

			ps.log_file.last.should be_a Pathname
			ps.log_file.last.to_s.should == 'error.log'
		end

		it "should support casting with lambda" do
			ps = CLI.new do
				option :size, :cast => lambda{|v| v.to_i + 2}
			end.parse(['--size', '24'])
			ps.size.should be_a Integer
			ps.size.should == 26
		end

		it "should support casting with class" do
			class Upcaser
				def initialize(string)
					@value = string.upcase
				end
				attr_reader :value
			end

			ps = CLI.new do
				option :text, :cast => Upcaser
			end.parse(['--text', 'hello world'])
			ps.text.should be_a Upcaser
			ps.text.value.should == 'HELLO WORLD'
		end

		it "should handle default values" do
			ps = CLI.new do
				option :location, :default => 'singapore'
				option :size, :cast => Integer, :default => 23
			end.parse([])
			ps.location.should be_a String
			ps.location.should == 'singapore'
			ps.size.should be_a Integer
			ps.size.should == 23
		end

		it "default value is casted" do
			ps = CLI.new do
				option :location, :default => 'singapore'
				option :size, :cast => Integer, :default => 23
			end.parse([])
			ps.location.should be_a String
			ps.location.should == 'singapore'
			ps.size.should be_a Integer
			ps.size.should == 23
		end

		it "not given and not defined options should be nil" do
			ps = CLI.new do
				option :size, :cast => Integer
			end.parse([])
			ps.size.should be_nil
			ps.gold.should be_nil
		end

		it "not given option that can be specified multiple times should be an empty array" do
			ps = CLI.new do
				options :size, :cast => Integer
			end.parse([])
			ps.size.should == []
		end

		it "should handle multiple long and short intermixed options" do
			ps = CLI.new do
				option :location, :short => :l
				option :group, :default => 'red'
				option :power_up, :short => :p
				option :speed, :short => :s, :cast => Integer
				option :not_given
				option :size
			end.parse(['-l', 'singapore', '--power-up', 'yes', '-s', '24', '--size', 'XXXL'])
			ps.group.should == 'red'
			ps.power_up.should == 'yes'
			ps.speed.should == 24
			ps.not_given.should be_nil
			ps.size.should == 'XXXL'
			ps.gold.should be_nil
		end

		it "should support options that can be specified multiple times" do
			ps = CLI.new do
				options :power_up, :short => :p
			end.parse(['--power-up', 'fire'])
			ps.power_up.should == ['fire']

			ps = CLI.new do
				options :power_up, :short => :p
			end.parse(['--power-up', 'fire', '-p', 'water', '--power-up', 'air', '-p', 'ground'])
			ps.power_up.should == ['fire', 'water', 'air', 'ground']
		end

		it "should support options that can be specified multiple times can have single default" do
			ps = CLI.new do
				options :power_up, :short => :p, :default => 'fire'
			end.parse([])
			ps.power_up.should == ['fire']
		end

		it "should support options that can be specified multiple times can have multiple defaults" do
			ps = CLI.new do
				options :power_up, :short => :p, :default => ['fire', 'air']
			end.parse([])
			ps.power_up.should == ['fire', 'air']
		end

		it "should raise error if not symbol and optional hash is passed" do
			lambda {
				ps = CLI.new do
					option 'number'
				end
			}.should raise_error CLI::ParserError::NameArgumetNotSymbolError, "option name has to be of type Symbol, got String"

			lambda {
				ps = CLI.new do
					option :number, :test
				end
			}.should raise_error CLI::ParserError::OptionsArgumentNotHashError, "option options has to be of type Hash, got Symbol"
		end

		it "should raise error on missing option argument" do
			ps = CLI.new do
				option :location
			end
			
			lambda {
				ps.parse(['--location'])
			}.should raise_error CLI::ParsingError::MissingOptionValueError, 'missing value for option --location'
		end

		it "should raise error on missing mandatory option" do
			ps = CLI.new do
				option :location
				option :weight, :required => true
				option :size, :required => true
				option :group, :default => 'red'
				option :speed, :short => :s, :cast => Integer
			end
			
			lambda {
				ps.parse([])
			}.should raise_error CLI::ParsingError::MandatoryOptionsNotSpecifiedError, "mandatory options not specified: --size, --weight"
		end

		it "by default option value should be nil" do
			ps = CLI.new do
				option :location
				option :speed, :short => :s, :cast => Integer
				option :weight, :required => true
				option :group, :default => 'red'
			end
			
			o = ps.parse(['--weight', '123'])

			o.location.should be_nil
			o.speed.should be_nil

			o.weight.should == '123'
			o.group.should == 'red'
		end
	end
end

