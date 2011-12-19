require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe CLI do
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
			}.should raise_error CLI::ParserError::ShortNameNotSymbolError, 'short name for --location has to be of type Symbol, got String'

			lambda {
				ps = CLI.new do
					switch :location, :short => :abc
				end
			}.should raise_error CLI::ParserError::ShortNameIsInvalidError, 'short name for --location has to be one letter symbol, got :abc'
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
end

