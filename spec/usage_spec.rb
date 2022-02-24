require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe CLI do
	describe "usage and description" do
		describe "help switch" do
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
        expect(ps.help).to be_nil
        expect(ps.location).to eq 'singapore'

				ps = ss.parse(['-h', '-l', 'singapore', '--power-up'])
        expect(ps.help).to be_a String
        expect(ps.location).to be_nil

				ps = ss.parse(['-l', 'singapore', '--power-up', '-h', 'yes', '-s', '24', '--size', 'XXXL', '/tmp', 'hello'])
        expect(ps.help).to be_a String
        expect(ps.location).to be_nil

				ps = ss.parse(['-l', 'singapore', '--power-up', '--help'])
        expect(ps.help).to be_a String
        expect(ps.location).to be_nil

				ps = ss.parse(['--help', '-l', 'singapore', '--power-up', 'yes', '-s', '24', '--size', 'XXXL', '/tmp', 'hello'])
        expect(ps.help).to be_a String
        expect(ps.location).to be_nil

				ps = ss.parse(['-l', 'singapore', '--power-up', 'yes', '-s', '24', '--size', 'XXXL', '/tmp', 'hello'])
        expect(ps.help).to be_nil
        expect(ps.location).to eq 'singapore'
			end

			it "parse! should cause program to exit and display help message on --help or -h switch" do
				expect(stdout_read do
					expect {
						ps = CLI.new do
						end.parse!(['--help'])
					}.to raise_error SystemExit
        end).to include('Usage:')

				expect(stdout_read do
					expect {
						ps = CLI.new do
						end.parse!(['-h'])
					}.to raise_error SystemExit
        end).to include('Usage:')
			end

			it "should reserve --help and -h switches" do
				expect {
					ps = CLI.new do
						switch :help
					end
				}.to raise_error CLI::ParserError::LongNameSpecifiedTwiceError, 'switch --help specified twice'

				expect {
					ps = CLI.new do
						switch :help2, :short => :h
					end
				}.to raise_error CLI::ParserError::ShortNameSpecifiedTwiceError, 'short switch -h specified twice'
			end

			it "should display help switch in the help message as the last entry" do
					expect(CLI.new do
						switch :test
          end.usage).to include("--test\n   --help (-h) - display this help message")
			end
		end

		describe "version" do
			it "should allow specifing version number that will be accessibel via --version switch" do
					ps = CLI.new do
						version '1.0.2'
					end.parse(['--version'])
          expect(ps.version).to eq "rspec version \"1.0.2\"\n"
			end

			it "parse! should cause program to exit displyaing version on --version switch" do
				expect(stdout_read do
					expect {
						ps = CLI.new do
							version "1.2.3"
						end.parse!(['--version'])
					}.to raise_error SystemExit
        end).to eq "rspec version \"1.2.3\"\n"
			end

			it "should display version switch in the help message as the last entry when version is specified" do
					expect(CLI.new do
          end.usage).not_to include("--version")

					expect(CLI.new do
						version '1.0.2'
          end.usage).to include("--help (-h) - display this help message\n   --version - display version string")
			end

			it "should reserve --version switch" do
				expect {
					ps = CLI.new do
						switch :version
					end
				}.not_to raise_error

				expect {
					ps = CLI.new do
						version '1.0.2'
						switch :version
					end
				}.to raise_error CLI::ParserError::LongNameSpecifiedTwiceError, 'switch --version specified twice'

				expect {
					ps = CLI.new do
						version '1.0.2'
						option :version
					end
				}.to raise_error CLI::ParserError::LongNameSpecifiedTwiceError, 'option and switch --version specified twice'
			end
		end

		it "should allow describing switches" do
			ss = CLI.new do
				switch :debug, :short => :d, :description => "enable debugging"
				switch :logging
			end

      expect(ss.usage).to include("enable debugging")
		end

		it "switch description should be casted to string" do
			ss = CLI.new do
				switch :debug, :short => :d, :description => 2 + 2
				switch :logging
			end

      expect(ss.usage).to include("4")
		end

		it "should allow describing options" do
			ss = CLI.new do
				option :location, :short => :l, :description => "place where server is located"
				option :group, :default => 'red'
			end

      expect(ss.usage).to include("place where server is located")
		end

		it "option description should be casted to string" do
			ss = CLI.new do
				option :location, :short => :l, :description => 2 + 2
				option :group, :default => 'red'
			end

      expect(ss.usage).to include("4")
		end

		it "should allow describing arguments" do
			ss = CLI.new do
				option :group, :default => 'red'
				argument :log, :cast => Pathname, :description => "log file to process"
			end

      expect(ss.usage).to include("log file to process")
		end

		it "argument description should be casted to string" do
			ss = CLI.new do
				option :group, :default => 'red'
				argument :log, :cast => Pathname, :description => 2 + 2
			end

      expect(ss.usage).to include("4")
		end

		it "should show default value for option" do
			ss = CLI.new do
				option :group, :default => 'red'
			end
      expect(ss.usage).to include("[red]")
		end

		it "should show default label for option" do
			ss = CLI.new do
				option :group, :default_label => 'blue'
			end
      expect(ss.usage).to include("[blue]")
		end

		it "should show default label rather than default value if available for option" do
			ss = CLI.new do
				option :group, :default_label => 'blue', :default => 'red'
			end
      expect(ss.usage).to include("[blue]")
      expect(ss.usage).not_to include("[red]")
		end

		it "should show default value for argument" do
			ss = CLI.new do
				argument :group, :default => 'red'
			end
      expect(ss.usage).to include("[red]")
		end

		it "should show default label for argument" do
			ss = CLI.new do
				argument :group, :default_label => 'blue'
			end
      expect(ss.usage).to include("[blue]")
		end

		it "should show default label rather than default value if available for argument" do
			ss = CLI.new do
				argument :group, :default_label => 'blue', :default => 'red'
			end
      expect(ss.usage).to include("[blue]")
      expect(ss.usage).not_to include("[red]")
		end

		describe "usage line" do
			it "should suggest that arguments can be used in usage line" do
				ss = CLI.new do
					argument :location
				end

				# switches will always be there due to implicit --help switch
        expect(ss.usage.lines.first).to eq "Usage: rspec [switches] [--] location\n"
			end

			it "should suggest that switches can be used in usage line" do
				ss = CLI.new do
					switch :location, :short => :l
				end

        expect(ss.usage.lines.first).to eq "Usage: rspec [switches]\n"
			end

			it "should suggest that options can be used in usage line" do
				ss = CLI.new do
					option :location, :short => :l
				end

				# switches will always be there due to implicit --help switch
        expect(ss.usage.lines.first).to eq "Usage: rspec [switches|options]\n"
			end

			it "should suggest that switches or options can be used in usage line" do
				ss = CLI.new do
					switch :location, :short => :l
					option :size, :short => :s
				end

        expect(ss.usage.lines.first).to eq "Usage: rspec [switches|options]\n"
			end

			it "should suggest that option is mandatory" do
				ss = CLI.new do
					option :size, :required => true
					option :group, :short => :g, :required => true
				end

				# switches will always be there due to implicit --help switch
        expect(ss.usage.lines.first).to eq "Usage: rspec [switches] --size <value> --group <value>\n"

				ss = CLI.new do
					option :location, :short => :l
					option :size, :required => true
					option :group, :short => :g, :required => true
				end

				# switches will always be there due to implicit --help switch
        expect(ss.usage.lines.first).to eq "Usage: rspec [switches|options] --size <value> --group <value>\n"

				ss = CLI.new do
					switch :location, :short => :l
					option :size, :short => :s, :required => true
				end

        expect(ss.usage.lines.first).to eq "Usage: rspec [switches] --size <value>\n"
			end

			it "should suggest that argument is optional" do
				ss = CLI.new do
					argument :location
					argument :size, :required => false
					argument :colour, :default => 'red'
					argument :group
				end

				# switches will always be there due to implicit --help switch
        expect(ss.usage.lines.first).to eq "Usage: rspec [switches] [--] location [size] [colour] group\n"
			end
		end

		it "should allow describing whole script" do
			ss = CLI.new do
				description 'Log file processor'
				option :group, :default => 'red'
				argument :log, :cast => Pathname
			end

      expect(ss.usage).to include("Log file processor")
		end

		it "should provide stdin usage information" do
			expect(CLI.new do
				stdin
      end.usage).to include(" < data")

			expect(CLI.new do
				stdin :log_file
      end.usage).to include(" < log-file")

			u = CLI.new do
				stdin :log_file, :description => 'log file to process'
			end.usage
      expect(u).to include(" < log-file")
      expect(u).to include("log file to process")

			u = CLI.new do
				stdin :log_data, :cast => YAML, :description => 'log data to process'
			end.usage
      expect(u).to include(" < log-data")
      expect(u).to include("log data to process")
		end

		it "should provide formated usage" do
			u = CLI.new do
				description 'Log file processor'
				version '1.0'
				stdin :log_data, :cast => YAML, :description => "YAML formatted log data"
				switch :debug, :short => :d, :description => "enable debugging"
				switch :logging, :short => :l
				switch :run
				option :location, :short => :r, :description => "place where server is located"
				option :group, :default => 'red', :default_label => 'colour'
				options :power_up, :short => :p, :required => true
				option :speed, :short => :s, :cast => Integer
				option :the_number_of_the_beast, :short => :b, :cast => Integer, :default => 666, :description => "The number of the beast"
				option :size

				argument :log, :cast => Pathname, :description => "log file to process"
				argument :magick, :default => 'word'
				argument :string
				argument :limit, :cast => Integer, :required => false, :description => "limit in seconds"
				argument :unlock_code, :cast => Integer, :required => false
				argument :code, :cast => Integer, :default => '123', :description => "secret code", :default_label => 'generated'
				argument :illegal_prime, :cast => Integer, :description => "prime number that represents information that it is forbidden to possess or distribute"
				arguments :files, :cast => Pathname, :default => ['test', '1', '2'], :description => "files to process"
			end.usage

      expect(u).to eq <<EOS
Usage: rspec [switches|options] --power-up <value> [--] log [magick] string [limit] [unlock-code] [code] illegal-prime [files*] < log-data
Log file processor
Input:
   log-data - YAML formatted log data
Switches:
   --debug (-d) - enable debugging
   --logging (-l)
   --run
   --help (-h) - display this help message
   --version - display version string
Options:
   --location (-r) - place where server is located
   --group [colour]
   --power-up* (-p) (mandatory)
   --speed (-s)
   --the-number-of-the-beast (-b) [666] - The number of the beast
   --size
Arguments:
   log - log file to process
   magick [word]
   string
   limit (optional) - limit in seconds
   unlock-code (optional)
   code [generated] - secret code
   illegal-prime - prime number that represents information that it is forbidden to possess or distribute
   files* [test 1 2] - files to process
EOS
		end
	end
end
