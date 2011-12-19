
require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe CLI do
	describe "name conflict reporting" do
		it "raise error when long names configlict" do
			lambda {
				ps = CLI.new do
					switch :location
					switch :location
				end
			}.should raise_error CLI::ParserError::LongNameSpecifiedTwiceError, 'switch --location specified twice'

			lambda {
				ps = CLI.new do
					option :location
					option :location
				end
			}.should raise_error CLI::ParserError::LongNameSpecifiedTwiceError, 'option --location specified twice'

			lambda {
				ps = CLI.new do
					switch :location
					option :location
				end
			}.should raise_error CLI::ParserError::LongNameSpecifiedTwiceError, 'switch and option --location specified twice'

			lambda {
				ps = CLI.new do
					option :location
					switch :location
				end
			}.should raise_error CLI::ParserError::LongNameSpecifiedTwiceError, 'option and switch --location specified twice'
		end
	end

	describe "short name conflict reporting" do
		it "raise error when short names configlict" do
			lambda {
				ps = CLI.new do
					switch :location, :short => :l
					switch :location2, :short => :l
				end
			}.should raise_error CLI::ParserError::ShortNameSpecifiedTwiceError, 'short switch -l specified twice'

			lambda {
				ps = CLI.new do
					option :location, :short => :l
					option :location2, :short => :l
				end
			}.should raise_error CLI::ParserError::ShortNameSpecifiedTwiceError, 'short option -l specified twice'

			lambda {
				ps = CLI.new do
					switch :location, :short => :l
					option :location2, :short => :l
				end
			}.should raise_error CLI::ParserError::ShortNameSpecifiedTwiceError, 'short switch and option -l specified twice'

			lambda {
				ps = CLI.new do
					option :location2, :short => :l
					switch :location, :short => :l
				end
			}.should raise_error CLI::ParserError::ShortNameSpecifiedTwiceError, 'short option and switch -l specified twice'
		end
	end
end

