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

		it "should cast mandatory argument" do
			ps = CLI.new do
				argument :log, :cast => Pathname
			end.parse(['/tmp'])
			ps.log.should be_a Pathname
			ps.log.to_s.should == '/tmp'
		end

		it "should cast mandatory argument to numerical class" do
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

		it "should cast default value" do
			ps = CLI.new do
				argument :number, :cast => Integer, :default => '123'
			end.parse([])
			ps.number.should be_a Integer
			ps.number.should == 123
		end

		it "should cast value of multiple arguments argument" do
			ps = CLI.new do
				arguments :numbers, :cast => Integer
			end.parse(['1', '2', '3'])
			ps.numbers.should be_a Array
			ps.numbers[0].should be_a Integer
			ps.numbers[0].should == 1
			ps.numbers[1].should be_a Integer
			ps.numbers[1].should == 2
			ps.numbers[2].should be_a Integer
			ps.numbers[2].should == 3
		end

		it "should cast single default value of multiple arguments argument" do
			ps = CLI.new do
				arguments :numbers, :cast => Integer, :default => '1'
			end.parse([])
			ps.numbers.should be_a Array
			ps.numbers[0].should be_a Integer
			ps.numbers[0].should == 1
		end

		it "should cast default value array of multiple arguments argument" do
			ps = CLI.new do
				arguments :numbers, :cast => Integer, :default => ['1', '2', '3']
			end.parse([])
			ps.numbers.should be_a Array
			ps.numbers[0].should be_a Integer
			ps.numbers[0].should == 1
			ps.numbers[1].should be_a Integer
			ps.numbers[1].should == 2
			ps.numbers[2].should be_a Integer
			ps.numbers[2].should == 3
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

		it "should handle multi arguments" do
			ps = CLI.new do
				argument :log, :cast => Pathname
				arguments :words
			end.parse(['/tmp', 'hello', 'world', 'test'])
			ps.log.should be_a Pathname
			ps.log.to_s.should == '/tmp'

			ps.words.should be_a Array
			ps.words[0].should == 'hello'
			ps.words[1].should == 'world'
			ps.words[2].should == 'test'
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
			}.should raise_error CLI::ParserError::ArgumentNameSpecifiedTwice, "argument 'number' specified twice"
		end

		it "should be required by default and raise error if not given" do
			lambda {
				ps = CLI.new do
					argument :log
				end.parse([])
			}.should raise_error CLI::ParsingError::MandatoryArgumentNotSpecifiedError, "mandatory argument 'log' not given"
		end

		it "should raise error if casting fail" do
			require 'ip'
			lambda {
				ps = CLI.new do
					argument :log, :cast => IP
				end.parse(['abc'])
			}.should raise_error CLI::ParsingError::CastError, "failed to cast: 'log' to type: IP: invalid address"
		end

		it "should raise error if multiple artuments argument defined twice" do
			lambda {
				ps = CLI.new do
					arguments :test1
					argument :test2
					arguments :test3
				end
			}.should raise_error CLI::ParserError::MultipleArgumentsSpecifierError, "only one 'arguments' specifier can be used, got: test1, test3"
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

			it "should fill multiple argumets argument with remaining arguments after filling mandatory and default arguments" do
				ps = CLI.new do
					argument :log, :cast => Pathname
					argument :magick, :default => 'word'
					argument :test
					arguments :words
					argument :test2
					argument :code, :cast => Integer, :default => '123'
				end.parse(['/tmp', 'number', 'test', 'hello', 'world', 'abc', 'test2', '42'])

				ps.log.to_s.should == '/tmp'
				ps.magick.should == 'number'
				ps.test.should == 'test'
				ps.words.should == ['hello', 'world', 'abc']
				ps.test2.should == 'test2'
				ps.code.should == 42
			end

			it "should use default single value for multiple arguments argument when not enought arguments given" do
				ps = CLI.new do
					argument :log, :cast => Pathname
					argument :magick, :default => 'word'
					argument :test
					arguments :words, :default => 'hello'
					argument :test2
					argument :code, :cast => Integer, :default => '123'
				end.parse(['/tmp', 'test', 'test2'])

				ps.log.to_s.should == '/tmp'
				ps.magick.should == 'word'
				ps.test.should == 'test'
				ps.words.should == ['hello']
				ps.test2.should == 'test2'
				ps.code.should == 123
			end

			it "should use default array of values for multiple arguments argument when not enought arguments given" do
				ps = CLI.new do
					argument :log, :cast => Pathname
					argument :magick, :default => 'word'
					argument :test
					arguments :words, :default => ['hello', 'world', 'abc']
					argument :test2
					argument :code, :cast => Integer, :default => '123'
				end.parse(['/tmp', 'test', 'test2'])

				ps.log.to_s.should == '/tmp'
				ps.magick.should == 'word'
				ps.test.should == 'test'
				ps.words.should == ['hello', 'world', 'abc']
				ps.test2.should == 'test2'
				ps.code.should == 123
			end
		end
	end
end

