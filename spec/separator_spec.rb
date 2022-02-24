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

      expect(ps.help).to be_nil
      expect(ps.location).to eq 'singapore'
      expect(ps.group).to eq 'red'
      expect(ps.debug).to be true
      expect(ps.test).to eq '--verbose'
      expect(ps.verbose).to be_nil

			ps = CLI.new do
				option :location, :short => :l
				option :group, :default => 'red'
				switch :debug
				switch :verbose
				argument :test
			end.parse(['-l', 'singapore', '--debug', '--help'])

      expect(ps.location).to be_nil
      expect(ps.group).to be_nil
      expect(ps.debug).to be_nil
      expect(ps.verbose).to be_nil
      expect(ps.help).not_to be_nil

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

      expect(ps.help).to be_nil
      expect(ps.location).to eq 'singapore'
      expect(ps.group).to eq 'red'
      expect(ps.debug).to be true
      expect(ps.test).to eq '--help'
      expect(ps.test2).to eq '--version'
      expect(ps.test3).to eq '-m'
      expect(ps.verbose).to be_nil
		end
	end
end
