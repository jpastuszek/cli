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

		it "should raise error if not given" do
			lambda {
				ps = CLI.new do
					argument :log
				end.parse([])
			}.should raise_error CLI::ParsingError
		end

		it "should raise error if casting fail" do
			require 'ip'
			lambda {
				ps = CLI.new do
					argument :log, :cast => IP
				end.parse(['abc'])
			}.should raise_error CLI::ParsingError, 'failed to cast: log to type: IP: invalid address'
		end

		describe "with defaults" do
			it "should use default first argument" do
				ps = CLI.new do
					argument :log, :cast => Pathname, :default => '/tmp'
					argument :test
				end.parse(['hello'])
				ps.log.should be_a Pathname
				ps.log.to_s.should == '/tmp'
				ps.test.should be_a String
				ps.test.should == 'hello'
			end

			it "should use default second argument" do
				ps = CLI.new do
					argument :log, :cast => Pathname
					argument :test, :default => 'hello'
				end.parse(['/tmp'])
				ps.log.should be_a Pathname
				ps.log.to_s.should == '/tmp'
				ps.test.should be_a String
				ps.test.should == 'hello'
			end

			it "should use default second argument" do
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

		it "should raise error on unrecognized switch" do
			ps = CLI.new do
				option :location
			end
			
			lambda {
				ps.parse(['--xxx'])
			}.should raise_error CLI::ParsingError
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

		it "should raise error on missing option argument" do
			ps = CLI.new do
				option :location
			end
			
			lambda {
				ps.parse(['--location'])
			}.should raise_error CLI::ParsingError
		end

		it "should raise error on missing required option" do
			ps = CLI.new do
				option :location
				option :size, :required => true
				option :group, :default => 'red'
				option :speed, :short => :s, :cast => Integer
			end
			
			lambda {
				ps.parse(['--location', 'singapore'])
			}.should raise_error CLI::ParsingError, "following options are required but were not specified: --size"
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

		it "should allow describing options" do
			ss = CLI.new do
				option :location, :short => :l, :description => "place where server is located"
				option :group, :default => 'red'
			end

			ss.usage.should include("place where server is located")
		end

		it "should allow describing arguments" do
			ss = CLI.new do
				option :group, :default => 'red'
				argument :log, :cast => Pathname, :description => "log file to process"
			end

			ss.usage.should include("log file to process")
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
				option :location, :short => :l, :description => "place where server is located"
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
   --location (-l) - place where server is located
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

