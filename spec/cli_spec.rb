require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'cli'

def stdin_write(data)
		r, w = IO.pipe
		old_stdin = STDIN.reopen r
		Thread.new do
		 	w.write data
			w.close
		end
		begin
			yield
		ensure
			STDIN.reopen old_stdin
		end
end

describe CLI do
	describe 'STDIN handling' do
		before :all do
			@yaml = <<EOF
--- 
:parser: 
  :successes: 41
  :failures: 0
EOF
		end

		it "should be nil if not specified" do
			ps = CLI.new.parse
			ps.stdin.should be_nil
		end

		it "should return IO if stdin is defined" do
			ps = CLI.new do
				stdin
			end.parse
			ps.stdin.should be_a IO
		end

		it "should return YAML document if stdin is casted to YAML" do
			ps = nil
			ss = CLI.new do
				stdin :log_data, :cast => YAML, :description => 'log statistic data in YAML format'
			end

			stdin_write(@yaml) do
				ps = ss.parse
			end

			ps.stdin.should == {:parser=>{:successes=>41, :failures=>0}}
		end
	end

	describe 'argument handling' do
		it "should handle single argument" do
			ps = CLI.new do
				argument :log
			end.parse(['/tmp'])
			ps.log.should be_a String
			ps.log.should == '/tmp'
		end

		it "non empty, non optional with class casting" do
			ps = CLI.new do
				argument :log, :cast => Pathname
			end.parse(['/tmp'])
			ps.log.should be_a Pathname
			ps.log.to_s.should == '/tmp'
		end

		it "non empty, non optional with builtin class casting" do
			ps = CLI.new do
				argument :number, :cast => Integer
			end.parse(['123'])
			ps.number.should be_a Integer
			ps.number.should == 123

			ps = CLI.new do
				argument :number, :cast => Float
			end.parse(['123'])
			ps.number.should be_a Float
			ps.number.should == 123.0
		end

		it "should handle multiple arguments" do
			ps = CLI.new do
				argument :log, :cast => Pathname
				argument :test
			end.parse(['/tmp', 'hello'])
			ps.log.should be_a Pathname
			ps.log.to_s.should == '/tmp'
			ps.test.should be_a String
			ps.test.should == 'hello'
		end

		it "should raise error if not symbol and optional hash is passed" do
			lambda {
				ps = CLI.new do
					argument 'number'
				end
			}.should raise_error CLI::ParserError::NameArgumetNotSymbolError, "argument name has to be of type Symbol, got String"

			lambda {
				ps = CLI.new do
					argument :number, :test
				end
			}.should raise_error CLI::ParserError::OptionsArgumentNotHashError, "argument options has to be of type Hash, got Symbol"
		end

		it "should raise error if artument name is specified twice" do
			lambda {
				ps = CLI.new do
					argument :number
					argument :number
				end
			}.should raise_error CLI::ParserError::ArgumentNameSpecifiedTwice, 'argument number specified twice'
		end

		it "should be required by default and raise error if not given" do
			lambda {
				ps = CLI.new do
					argument :log
				end.parse([])
			}.should raise_error CLI::ParsingError::MandatoryArgumentNotSpecifiedError, 'mandatory argument log not given'
		end

		it "should raise error if casting fail" do
			require 'ip'
			lambda {
				ps = CLI.new do
					argument :log, :cast => IP
				end.parse(['abc'])
			}.should raise_error CLI::ParsingError::CastError, 'failed to cast: log to type: IP: invalid address'
		end

		describe "with defaults" do
			it "when not enought arguments given it should fill required arguments only with defaults" do
				ps = CLI.new do
					argument :log, :cast => Pathname, :default => '/tmp'
					argument :test
				end.parse(['hello'])
				ps.log.should be_a Pathname
				ps.log.to_s.should == '/tmp'
				ps.test.should be_a String
				ps.test.should == 'hello'

				ps = CLI.new do
					argument :log, :cast => Pathname
					argument :test, :default => 'hello'
				end.parse(['/tmp'])
				ps.log.should be_a Pathname
				ps.log.to_s.should == '/tmp'
				ps.test.should be_a String
				ps.test.should == 'hello'

				ps = CLI.new do
					argument :log, :cast => Pathname
					argument :magick, :default => 'word'
					argument :test
					argument :code, :cast => Integer, :default => '123'
				end.parse(['/tmp', 'hello'])
				ps.log.to_s.should == '/tmp'
				ps.magick.should == 'word'
				ps.test.should == 'hello'
				ps.code.should == 123
			end

			it "should fill defaults form the beginning if more than required arguments are given" do
				ps = CLI.new do
					argument :log, :cast => Pathname
					argument :magick, :default => 'word'
					argument :test
					argument :code, :cast => Integer, :default => '123'
				end.parse(['/tmp', 'hello', 'world'])
				ps.log.to_s.should == '/tmp'
				ps.magick.should == 'hello'
				ps.test.should == 'world'
				ps.code.should == 123
			end
		end
	end

	describe 'switch handling' do
		it "should handle long switch names" do
			ps = CLI.new do
				switch :location
				switch :unset
			end.parse(['--location'])
			ps.location.should be_true
			ps.unset.should be_nil
		end

		it "should handle short switch names" do
			ps = CLI.new do
				switch :location, :short => :l
				switch :unset, :short => :u
			end.parse(['-l'])
			ps.location.should be_true
			ps.unset.should be_nil
		end

		it "should raise error if not symbol and optional hash is passed" do
			lambda {
				ps = CLI.new do
					switch 'number'
				end.parse([])
			}.should raise_error CLI::ParserError::NameArgumetNotSymbolError, "switch name has to be of type Symbol, got String"

			lambda {
				ps = CLI.new do
					switch :number, :test
				end
			}.should raise_error CLI::ParserError::OptionsArgumentNotHashError, "switch options has to be of type Hash, got Symbol"
		end

		it "shoud raise error is short name is invalid" do
			lambda {
				ps = CLI.new do
					switch :location, :short => "l"
				end
			}.should raise_error CLI::ParserError::ShortNameNotSymbolError, 'short name has to be of type Symbol, got String'

			lambda {
				ps = CLI.new do
					switch :location, :short => :abc
				end
			}.should raise_error CLI::ParserError::ShortNameIsInvalidError, 'short name has to be one letter symbol, got abc'
		end

		it "should raise error on unrecognized switch" do
			ps = CLI.new do
				option :location
			end
			
			lambda {
				ps.parse(['--xxx'])
			}.should raise_error CLI::ParsingError::UnknownSwitchError, 'unknown switch --xxx'
		end
	end

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

	it "should handle options, switches and then arguments" do
		ps = CLI.new do
			option :location, :short => :l
			option :group, :default => 'red'
			option :power_up, :short => :p
			option :speed, :short => :s, :cast => Integer
			option :size
			switch :debug

			argument :log, :cast => Pathname
			argument :magick, :default => 'word'
			argument :test
			argument :code, :cast => Integer, :default => '123'
		end.parse(['-l', 'singapore', '--power-up', 'yes', '-s', '24', '--debug', '--size', 'XXXL', '/tmp', 'hello'])

		ps.group.should == 'red'
		ps.power_up.should == 'yes'
		ps.speed.should == 24
		ps.size.should == 'XXXL'

		ps.log.to_s.should == '/tmp'
		ps.magick.should == 'word'
		ps.test.should == 'hello'
		ps.code.should == 123
		ps.debug.should be_true
	end

	describe "name conflict reporting" do
		it "raise error when long names configlict" do
			lambda {
				ps = CLI.new do
					switch :location
					switch :location
				end
			}.should raise_error CLI::ParserError::LongNameSpecifiedTwiceError, 'switch location specified twice'

			lambda {
				ps = CLI.new do
					option :location
					option :location
				end
			}.should raise_error CLI::ParserError::LongNameSpecifiedTwiceError, 'option location specified twice'

			lambda {
				ps = CLI.new do
					switch :location
					option :location
				end
			}.should raise_error CLI::ParserError::LongNameSpecifiedTwiceError, 'switch and option location specified twice'

			lambda {
				ps = CLI.new do
					option :location
					switch :location
				end
			}.should raise_error CLI::ParserError::LongNameSpecifiedTwiceError, 'option and switch location specified twice'
		end
	end

	describe "short name conflict reporting" do
		it "raise error when short names configlict" do
			lambda {
				ps = CLI.new do
					switch :location, :short => :l
					switch :location2, :short => :l
				end
			}.should raise_error CLI::ParserError::ShortNameSpecifiedTwiceError, 'short switch l specified twice'

			lambda {
				ps = CLI.new do
					option :location, :short => :l
					option :location2, :short => :l
				end
			}.should raise_error CLI::ParserError::ShortNameSpecifiedTwiceError, 'short option l specified twice'

			lambda {
				ps = CLI.new do
					switch :location, :short => :l
					option :location2, :short => :l
				end
			}.should raise_error CLI::ParserError::ShortNameSpecifiedTwiceError, 'short switch and option l specified twice'

			lambda {
				ps = CLI.new do
					option :location2, :short => :l
					switch :location, :short => :l
				end
			}.should raise_error CLI::ParserError::ShortNameSpecifiedTwiceError, 'short option and switch l specified twice'
		end
	end

	describe "usage and description" do
		it "parse should set help variable if -h or --help specified in the argument list and not parse the input" do
			ss = CLI.new do
				option :location, :short => :l
				option :group, :default => 'red'
				option :power_up, :short => :p
				option :speed, :short => :s, :cast => Integer
				option :size
				switch :debug

				argument :log, :cast => Pathname
				argument :magick, :default => 'word'
				argument :test
				argument :code, :cast => Integer, :default => '123'
			end
			
			ps = ss.parse(['-l', 'singapore', '--power-up', 'yes', '-s', '24', '--size', 'XXXL', '/tmp', 'hello'])
			ps.help.should be_nil
			ps.location.should == 'singapore'

			ps = ss.parse(['-h', '-l', 'singapore', '--power-up'])
			ps.help.should be_a String
			ps.location.should be_nil

			ps = ss.parse(['-l', 'singapore', '--power-up', '-h', 'yes', '-s', '24', '--size', 'XXXL', '/tmp', 'hello'])
			ps.help.should be_a String
			ps.location.should be_nil

			ps = ss.parse(['-l', 'singapore', '--power-up', '--help'])
			ps.help.should be_a String
			ps.location.should be_nil

			ps = ss.parse(['--help', '-l', 'singapore', '--power-up', 'yes', '-s', '24', '--size', 'XXXL', '/tmp', 'hello'])
			ps.help.should be_a String
			ps.location.should be_nil

			ps = ss.parse(['-l', 'singapore', '--power-up', 'yes', '-s', '24', '--size', 'XXXL', '/tmp', 'hello'])
			ps.help.should be_nil
			ps.location.should == 'singapore'
		end

		it "should allow describing switches" do
			ss = CLI.new do
				switch :debug, :short => :d, :description => "enable debugging"
				switch :logging
			end

			ss.usage.should include("enable debugging")
		end

		it "switch description should be casted to string" do
			ss = CLI.new do
				switch :debug, :short => :d, :description => 2 + 2
				switch :logging
			end

			ss.usage.should include("4")
		end

		it "should allow describing options" do
			ss = CLI.new do
				option :location, :short => :l, :description => "place where server is located"
				option :group, :default => 'red'
			end

			ss.usage.should include("place where server is located")
		end

		it "option description should be casted to string" do
			ss = CLI.new do
				option :location, :short => :l, :description => 2 + 2
				option :group, :default => 'red'
			end

			ss.usage.should include("4")
		end

		it "should allow describing arguments" do
			ss = CLI.new do
				option :group, :default => 'red'
				argument :log, :cast => Pathname, :description => "log file to process"
			end

			ss.usage.should include("log file to process")
		end

		it "argument description should be casted to string" do
			ss = CLI.new do
				option :group, :default => 'red'
				argument :log, :cast => Pathname, :description => 2 + 2
			end

			ss.usage.should include("4")
		end

		it "should suggest that switches can be used in usage line" do
			ss = CLI.new do
				switch :location, :short => :l
			end

			ss.usage.first.should == "Usage: rspec [switches]\n"
		end

		it "should suggest that options can be used in usage line" do
			ss = CLI.new do
				option :location, :short => :l
			end

			ss.usage.first.should == "Usage: rspec [options]\n"
		end

		it "should suggest that switches or options can be used in usage line" do
			ss = CLI.new do
				switch :location, :short => :l
				option :size, :short => :s
			end

			ss.usage.first.should == "Usage: rspec [switches|options]\n"
		end

		it "should allow describing whole script" do
			ss = CLI.new do
				description 'Log file processor'
				option :group, :default => 'red'
				argument :log, :cast => Pathname
			end

			ss.usage.should include("Log file processor")
		end

		it "should provide stdin usage information" do
			CLI.new do
				stdin
			end.usage.should include(" < data")

			CLI.new do
				stdin :log_file
			end.usage.should include(" < log-file")

			u = CLI.new do
				stdin :log_file, :description => 'log file to process'
			end.usage
			u.should include(" < log-file")
			u.should include("log file to process")

			u = CLI.new do
				stdin :log_data, :cast => YAML, :description => 'log data to process'
			end.usage
			u.should include(" < log-data")
			u.should include("log data to process")
		end

		it "should provide formated usage with optional message" do
			u = CLI.new do
				description 'Log file processor'
				stdin :log_data, :cast => YAML, :description => "YAML formatted log data"
				switch :debug, :short => :d, :description => "enable debugging"
				switch :logging, :short => :l
				switch :run
				option :location, :short => :r, :description => "place where server is located"
				option :group, :default => 'red'
				option :power_up, :short => :p
				option :speed, :short => :s, :cast => Integer
				option :the_number_of_the_beast, :short => :b, :cast => Integer, :default => 666, :description => "The number of the beast"
				option :size

				argument :log, :cast => Pathname, :description => "log file to process"
				argument :magick, :default => 'word'
				argument :string
				argument :number, :cast => Integer
				argument :code, :cast => Integer, :default => '123', :description => "secret code"
				argument :illegal_prime, :cast => Integer, :description => "prime number that represents information that it is forbidden to possess or distribute"
			end.usage

			#puts u

			u.should == <<EOS
Usage: rspec [switches|options] log magick string number code illegal-prime < log-data
Log file processor
Input:
   log-data - YAML formatted log data
Switches:
   --debug (-d) - enable debugging
   --logging (-l)
   --run
Options:
   --location (-r) - place where server is located
   --group [red]
   --power-up (-p)
   --speed (-s)
   --the-number-of-the-beast (-b) [666] - The number of the beast
   --size
Arguments:
   log - log file to process
   code - secret code
   illegal-prime - prime number that represents information that it is forbidden to possess or distribute
EOS
		end
	end
end

