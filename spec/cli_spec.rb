require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe CLI do
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

	it "provides name method that provides current program name" do
		CLI.name.should == 'rspec'
	end

	describe "parse!" do
		it "should return value structure with all the values on successful parsing" do
			ps = CLI.new do
				option :location, :short => :l
				switch :debug
				argument :code
			end.parse!(['-l', 'singapore', '--debug', 'hello'])

			ps.location.should == 'singapore'
			ps.debug.should be_true
			ps.code.should == 'hello'
		end

		it "should return value structure where all values are set" do
			h = CLI.new do
				option :location, :short => :l
				switch :debug
			end.parse!([]).marshal_dump

			h.member?(:location).should be_true
			h[:location].should be_nil

			h.member?(:debug).should be_true
			h[:debug].should be_nil
		end

		it "should take a block that can be used to verify passed values" do
			lambda {
				ps = CLI.new do
					option :location, :short => :l
					switch :debug
					switch :verbose
					argument :code
				end.parse!(['-l', 'singapore', '--debug', 'hello']) do |values|
					fail '--debug can not be used with --verbose' if values.debug and values.verbose
				end
			}.should_not raise_error

			out = stderr_read do
				lambda {
					ps = CLI.new do
						option :location, :short => :l
						switch :debug
						switch :verbose
						argument :code
					end.parse!(['-l', 'singapore', '--debug', '--verbose', 'hello']) do |values|
						fail '--debug can not be used with --verbose' if values.debug and values.verbose
					end
					}.should raise_error SystemExit
				end
				out.should include('Error: --debug can not be used with --verbose')
				out.should include('Usage:')
		end

		it "should exit displaying usage and error message on standard error on usage error" do
				out = stderr_read do
					lambda {
						ps = CLI.new do
							option :weight, :required => true
						end.parse!([])
					}.should raise_error SystemExit
				end
				out.should include('Error: mandatory options not specified: --weight')
				out.should include('Usage:')
		end
	end
end

