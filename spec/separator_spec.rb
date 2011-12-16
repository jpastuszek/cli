require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe CLI do
	describe "argument separator" do
		it "should allow separating arguments from switches so that arguments can contain switch like elements" do
			ps = CLI.new do
				option :location, :short => :l
				option :group, :default => 'red'
				switch :debug
				switch :verbose
				argument :test
			end.parse(['-l', 'singapore', '--debug', '--', '--verbose'])

			ps.help.should be_nil
			ps.location.should == 'singapore'
			ps.group.should == 'red'
			ps.debug.should be_true
			ps.test.should == '--verbose'
			ps.verbose.should be_nil

			ps = CLI.new do
				option :location, :short => :l
				option :group, :default => 'red'
				switch :debug
				switch :verbose
				argument :test
			end.parse(['-l', 'singapore', '--debug', '--help'])

			ps.location.should be_nil
			ps.group.should be_nil
			ps.debug.should be_nil
			ps.verbose.should be_nil
			ps.help.should_not be_nil

			ps = CLI.new do
				option :location, :short => :l
				option :group, :default => 'red'
				switch :debug
				switch :merge, :short => :m
				switch :verbose
				argument :test
				argument :test2
				argument :test3
			end.parse(['-l', 'singapore', '--debug', '--', '--help', '--version', '-m'])

			ps.help.should be_nil
			ps.location.should == 'singapore'
			ps.group.should == 'red'
			ps.debug.should be_true
			ps.test.should == '--help'
			ps.test2.should == '--version'
			ps.test3.should == '-m'
			ps.verbose.should be_nil
		end
	end
end

