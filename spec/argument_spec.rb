require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe CLI do
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
end

