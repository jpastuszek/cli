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
				option :size, :cast => Integer, :default => 23.99
			end.parse([])
			ps.location.should be_a String
			ps.location.should == 'singapore'
			ps.size.should be_a Integer
			ps.size.should == 23
		end

		it "should support casting" do
			ps = CLI.new do
				option :size, :cast => Integer
			end.parse(['--size', '24'])
			ps.size.should be_a Integer
			ps.size.should == 24
		end

		it "not given and not defined options should be nil" do
			ps = CLI.new do
				option :size, :cast => Integer
			end.parse([])
			ps.size.should be_nil
			ps.gold.should be_nil
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

