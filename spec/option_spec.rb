require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe CLI do
	describe 'option handling' do
		it "should handle long option names" do
			ps = CLI.new do
				option :location
			end.parse(['--location', 'singapore'])
      expect(ps.location).to be_a String
      expect(ps.location).to eq 'singapore'
		end

		it "should handle short option names" do
			ps = CLI.new do
				option :location, :short => :l
			end.parse(['-l', 'singapore'])
      expect(ps.location).to be_a String
      expect(ps.location).to eq 'singapore'
		end

		it "should support casting" do
			ps = CLI.new do
				option :size, :cast => Integer
			end.parse(['--size', '24'])
      expect(ps.size).to be_a Integer
      expect(ps.size).to eq 24
		end

		it "casting should fail if not proper integer given" do
			expect {
				ps = CLI.new do
					option :size, :cast => Integer
				end.parse(['--size', '24.99'])
			}.to raise_error(CLI::ParsingError::CastError)
		end

		it "casting should fail if not proper float given" do
			expect {
				ps = CLI.new do
					option :size, :cast => Float
				end.parse(['--size', '24.99x'])
			}.to raise_error(CLI::ParsingError::CastError)
		end

		it "casting should fail if there is error in cast lambda" do
			expect {
				ps = CLI.new do
					option :size, :cast => lambda{|v| fail 'test'}
				end.parse(['--size', '24.99x'])
			}.to raise_error(CLI::ParsingError::CastError)
		end

		it "should support casting of multiple options" do
			ps = CLI.new do
				options :size, :cast => Integer
			end.parse(['--size', '24', '--size', '10'])
      expect(ps.size).to be_a Array
      expect(ps.size).to eq [24, 10]
		end

		it "should support casting of multiple options with default" do
			ps = CLI.new do
				options :log_file, :cast => Pathname, :default => 'test.log'
			end.parse(['--log-file', 'server.log', '--log-file', 'error.log'])

      expect(ps.log_file).to be_a Array
      expect(ps.log_file.length).to eq 2

      expect(ps.log_file.first).to be_a Pathname
      expect(ps.log_file.first.to_s).to eq 'server.log'

      expect(ps.log_file.last).to be_a Pathname
      expect(ps.log_file.last.to_s).to eq 'error.log'
		end

		it "should support casting with lambda" do
			ps = CLI.new do
				option :size, :cast => lambda{|v| v.to_i + 2}
			end.parse(['--size', '24'])
      expect(ps.size).to be_a Integer
      expect(ps.size).to eq 26
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
      expect(ps.text).to be_a Upcaser
      expect(ps.text.value).to eq 'HELLO WORLD'
		end

		it "should handle default values" do
			ps = CLI.new do
				option :location, :default => 'singapore'
				option :size, :cast => Integer, :default => 23
			end.parse([])
      expect(ps.location).to be_a String
      expect(ps.location).to eq 'singapore'
      expect(ps.size).to be_a Integer
      expect(ps.size).to eq 23
		end

		it "default value is casted" do
			ps = CLI.new do
				option :location, :default => 'singapore'
				option :size, :cast => Integer, :default => 23
			end.parse([])
      expect(ps.location).to be_a String
      expect(ps.location).to eq 'singapore'
      expect(ps.size).to be_a Integer
      expect(ps.size).to eq 23
		end

		it "not given and not defined options should be nil" do
			ps = CLI.new do
				option :size, :cast => Integer
			end.parse([])
      expect(ps.size).to be_nil
      expect(ps.gold).to be_nil
		end

		it "not given option that can be specified multiple times should be an empty array" do
			ps = CLI.new do
				options :size, :cast => Integer
			end.parse([])
      expect(ps.size).to eq []
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
      expect(ps.group).to eq 'red'
      expect(ps.power_up).to eq 'yes'
      expect(ps.speed).to eq 24
      expect(ps.not_given).to be_nil
      expect(ps.size).to eq 'XXXL'
      expect(ps.gold).to be_nil
		end

		it "should support options that can be specified multiple times" do
			ps = CLI.new do
				options :power_up, :short => :p
			end.parse(['--power-up', 'fire'])
      expect(ps.power_up).to eq ['fire']

			ps = CLI.new do
				options :power_up, :short => :p
			end.parse(['--power-up', 'fire', '-p', 'water', '--power-up', 'air', '-p', 'ground'])
      expect(ps.power_up).to eq ['fire', 'water', 'air', 'ground']
		end

		it "should support options that can be specified multiple times can have single default" do
			ps = CLI.new do
				options :power_up, :short => :p, :default => 'fire'
			end.parse([])
      expect(ps.power_up).to eq ['fire']
		end

		it "should support options that can be specified multiple times can have multiple defaults" do
			ps = CLI.new do
				options :power_up, :short => :p, :default => ['fire', 'air']
			end.parse([])
      expect(ps.power_up).to eq ['fire', 'air']
		end

		it "should raise error if not symbol and optional hash is passed" do
			expect {
				ps = CLI.new do
					option 'number'
				end
			}.to raise_error CLI::ParserError::NameArgumetNotSymbolError, "option name has to be of type Symbol, got String"

			expect {
				ps = CLI.new do
					option :number, :test
				end
			}.to raise_error CLI::ParserError::OptionsArgumentNotHashError, "option options has to be of type Hash, got Symbol"
		end

		it "should raise error on missing option argument" do
			ps = CLI.new do
				option :location
			end

			expect {
				ps.parse(['--location'])
			}.to raise_error CLI::ParsingError::MissingOptionValueError, 'missing value for option --location'
		end

		it "should raise error on missing mandatory option" do
			ps = CLI.new do
				option :location
				option :weight, :required => true
				option :size, :required => true
				option :group, :default => 'red'
				option :speed, :short => :s, :cast => Integer
			end

			expect {
				ps.parse([])
			}.to raise_error CLI::ParsingError::MandatoryOptionsNotSpecifiedError, "mandatory options not specified: --size, --weight"
		end

		it "by default option value should be nil" do
			ps = CLI.new do
				option :location
				option :speed, :short => :s, :cast => Integer
				option :weight, :required => true
				option :group, :default => 'red'
			end

			o = ps.parse(['--weight', '123'])

      expect(o.location).to be_nil
      expect(o.speed).to be_nil

      expect(o.weight).to eq '123'
      expect(o.group).to eq 'red'
		end
	end
end
