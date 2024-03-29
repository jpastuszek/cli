require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe CLI do
	describe 'argument handling' do
		it "should handle single argument" do
			ps = CLI.new do
				argument :log
			end.parse(['/tmp'])
      expect(ps.log).to be_a String
      expect(ps.log).to eq '/tmp'
		end

		it "should cast mandatory argument" do
			ps = CLI.new do
				argument :log, :cast => Pathname
			end.parse(['/tmp'])
      expect(ps.log).to be_a Pathname
      expect(ps.log.to_s).to eq '/tmp'
		end

		it "should cast mandatory argument to numerical class" do
			ps = CLI.new do
				argument :number, :cast => Integer
			end.parse(['123'])
      expect(ps.number).to be_a Integer
      expect(ps.number).to eq 123

			ps = CLI.new do
				argument :number, :cast => Float
			end.parse(['123'])
      expect(ps.number).to be_a Float
      expect(ps.number).to eq 123.0
		end

		it "casting should fail if not proper integer given" do
			expect {
				ps = CLI.new do
					argument :size, :cast => Integer
				end.parse(['24.99'])
			}.to raise_error(CLI::ParsingError::CastError)
		end

		it "casting should fail if not proper float given" do
			expect {
				ps = CLI.new do
					argument :size, :cast => Float
				end.parse(['24.99x'])
			}.to raise_error(CLI::ParsingError::CastError)
		end

		it "casting should fail if there is error in cast lambda" do
			expect {
				ps = CLI.new do
					argument :size, :cast => lambda{|v| fail 'test'}
				end.parse(['24.99x'])
			}.to raise_error(CLI::ParsingError::CastError)
		end

		it "should cast default value" do
			ps = CLI.new do
				argument :number, :cast => Integer, :default => '123'
			end.parse([])
      expect(ps.number).to be_a Integer
      expect(ps.number).to eq 123
		end

		it "should cast value of multiple arguments argument" do
			ps = CLI.new do
				arguments :numbers, :cast => Integer
			end.parse(['1', '2', '3'])
      expect(ps.numbers).to be_a Array
      expect(ps.numbers[0]).to be_a Integer
      expect(ps.numbers[0]).to eq 1
      expect(ps.numbers[1]).to be_a Integer
      expect(ps.numbers[1]).to eq 2
      expect(ps.numbers[2]).to be_a Integer
      expect(ps.numbers[2]).to eq 3
		end

		it "should cast single default value of multiple arguments argument" do
			ps = CLI.new do
				arguments :numbers, :cast => Integer, :default => '1'
			end.parse([])
      expect(ps.numbers).to be_a Array
      expect(ps.numbers[0]).to be_a Integer
      expect(ps.numbers[0]).to eq 1
		end

		it "should cast default value array of multiple arguments argument" do
			ps = CLI.new do
				arguments :numbers, :cast => Integer, :default => ['1', '2', '3']
			end.parse([])
      expect(ps.numbers).to be_a Array
      expect(ps.numbers[0]).to be_a Integer
      expect(ps.numbers[0]).to eq 1
      expect(ps.numbers[1]).to be_a Integer
      expect(ps.numbers[1]).to eq 2
      expect(ps.numbers[2]).to be_a Integer
      expect(ps.numbers[2]).to eq 3
		end

		it "should handle multiple arguments" do
			ps = CLI.new do
				argument :log, :cast => Pathname
				argument :test
			end.parse(['/tmp', 'hello'])
      expect(ps.log).to be_a Pathname
      expect(ps.log.to_s).to eq '/tmp'
      expect(ps.test).to be_a String
      expect(ps.test).to eq 'hello'
		end

		it "should handle multi arguments" do
			ps = CLI.new do
				argument :log, :cast => Pathname
				arguments :words
			end.parse(['/tmp', 'hello', 'world', 'test'])
      expect(ps.log).to be_a Pathname
      expect(ps.log.to_s).to eq '/tmp'

      expect(ps.words).to be_a Array
      expect(ps.words[0]).to eq 'hello'
      expect(ps.words[1]).to eq 'world'
      expect(ps.words[2]).to eq 'test'
		end

		it "should raise error if not symbol and optional hash is passed" do
			expect {
				ps = CLI.new do
					argument 'number'
				end
			}.to raise_error CLI::ParserError::NameArgumetNotSymbolError, "argument name has to be of type Symbol, got String"

			expect {
				ps = CLI.new do
					argument :number, :test
				end
			}.to raise_error CLI::ParserError::OptionsArgumentNotHashError, "argument options has to be of type Hash, got Symbol"
		end

		it "should raise error if artument name is specified twice" do
			expect {
				ps = CLI.new do
					argument :number
					argument :number
				end
			}.to raise_error CLI::ParserError::ArgumentNameSpecifiedTwice, "argument 'number' specified twice"
		end

		it "should be required by default and raise error if not given" do
			expect {
				ps = CLI.new do
					argument :log
				end.parse([])
			}.to raise_error CLI::ParsingError::MandatoryArgumentNotSpecifiedError, "mandatory argument 'log' not given"
		end

		it "should raise error if casting fail" do
			require 'ip'
			expect {
				ps = CLI.new do
					argument :log, :cast => IP
				end.parse(['abc'])
			}.to raise_error CLI::ParsingError::CastError, "failed to cast: 'log' to type: IP: invalid address"
		end

		it "should raise error if multiple artuments argument defined twice" do
			expect {
				ps = CLI.new do
					arguments :test1
					argument :test2
					arguments :test3
				end
			}.to raise_error CLI::ParserError::MultipleArgumentsSpecifierError, "only one 'arguments' specifier can be used, got: test1, test3"
		end

		describe "with defaults" do
			it "should fill defaults form the beginning if more than required arguments are given" do
				ps = CLI.new do
					argument :test1, :default => 'x'
					argument :test2
					argument :test3, :default => 'c'
					argument :test4, :default => 'd'
					argument :test5, :default => 'e'
				end.parse(['a', 'b'])
        expect(ps.test1).to eq 'a'
        expect(ps.test2).to eq 'b'
        expect(ps.test3).to eq 'c'
        expect(ps.test4).to eq 'd'
        expect(ps.test5).to eq 'e'

				ps = CLI.new do
					argument :log, :cast => Pathname
					argument :magick, :default => 'word'
					argument :test
					argument :code, :cast => Integer, :default => '123'
				end.parse(['/tmp', 'hello', 'world'])
        expect(ps.log.to_s).to eq '/tmp'
        expect(ps.magick).to eq 'hello'
        expect(ps.test).to eq 'world'
        expect(ps.code).to eq 123
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

        expect(ps.log.to_s).to eq '/tmp'
        expect(ps.magick).to eq 'number'
        expect(ps.test).to eq 'test'
        expect(ps.words).to eq ['hello', 'world', 'abc']
        expect(ps.test2).to eq 'test2'
        expect(ps.code).to eq 42
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

        expect(ps.log.to_s).to eq '/tmp'
        expect(ps.magick).to eq 'word'
        expect(ps.test).to eq 'test'
        expect(ps.words).to eq ['hello']
        expect(ps.test2).to eq 'test2'
        expect(ps.code).to eq 123
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

        expect(ps.log.to_s).to eq '/tmp'
        expect(ps.magick).to eq 'word'
        expect(ps.test).to eq 'test'
        expect(ps.words).to eq ['hello', 'world', 'abc']
        expect(ps.test2).to eq 'test2'
        expect(ps.code).to eq 123
			end

			it "should fill at least one value of required multiple arguments argument" do
				ps = CLI.new do
					argument :test1, :default => 'x'
					argument :test2, :default => 'b'
					arguments :test3
					argument :test4, :default => 'd'
					argument :test5, :default => 'e'
				end.parse(['a', 'c'])
        expect(ps.test1).to eq 'a'
        expect(ps.test2).to eq 'b'
        expect(ps.test3).to eq ['c']
        expect(ps.test4).to eq 'd'
        expect(ps.test5).to eq 'e'
			end
		end

		describe "not required"  do
			it "argument that is not required may be nil if there is not enought command arguments" do
				ps = CLI.new do
					argument :test1, :required => false
					argument :test2, :required => false
					argument :test3, :required => false
					argument :test4, :required => false
					argument :test5, :required => false
				end.parse(['a', 'b'])
        expect(ps.test1).to eq 'a'
        expect(ps.test2).to eq 'b'
        expect(ps.test3).to be_nil
        expect(ps.test4).to be_nil
        expect(ps.test5).to be_nil

				ps = CLI.new do
					argument :log, :cast => Pathname
					argument :test, :required => false
				end.parse(['/tmp'])
        expect(ps.log).to be_a Pathname
        expect(ps.log.to_s).to eq '/tmp'
        expect(ps.test).to be_nil
			end

			it "should use empty array for multiple arguments argument when not enought arguments given and it is not required" do
				ps = CLI.new do
					argument :test1, :required => false
					argument :test2, :required => false
					arguments :test3, :required => false
				end.parse(['a', 'b'])
        expect(ps.test1).to eq 'a'
        expect(ps.test2).to eq 'b'
        expect(ps.test3).to eq []

				ps = CLI.new do
					argument :log, :cast => Pathname
					argument :magick, :default => 'word'
					argument :test
					arguments :words, :required => false
					argument :test2
					argument :code, :cast => Integer, :default => '123'
				end.parse(['/tmp', 'test', 'test2'])

        expect(ps.log.to_s).to eq '/tmp'
        expect(ps.magick).to eq 'word'
        expect(ps.test).to eq 'test'
        expect(ps.words).to eq []
        expect(ps.test2).to eq 'test2'
        expect(ps.code).to eq 123
			end
		end
	end
end
