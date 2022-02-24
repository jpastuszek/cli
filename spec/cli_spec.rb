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

    expect(ps.group).to eq 'red'
    expect(ps.power_up).to eq 'yes'
    expect(ps.speed).to eq 24
    expect(ps.size).to eq 'XXXL'

    expect(ps.log.to_s).to eq '/tmp'
    expect(ps.magick).to eq 'word'
    expect(ps.test).to eq 'hello'
    expect(ps.code).to eq 123
    expect(ps.debug).to be true
	end

	it "provides name method that provides current program name" do
    expect(CLI.name).to eq 'rspec'
	end

	describe "parse!" do
		it "should return value structure with all the values on successful parsing" do
			ps = CLI.new do
				option :location, :short => :l
				switch :debug
				argument :code
			end.parse!(['-l', 'singapore', '--debug', 'hello'])

      expect(ps.location).to eq 'singapore'
      expect(ps.debug).to be true
      expect(ps.code).to eq 'hello'
		end

		it "should return value structure where all values are set" do
			h = CLI.new do
				option :location, :short => :l
				switch :debug
			end.parse!([]).marshal_dump

      expect(h.member?(:location)).to be true
      expect(h[:location]).to be_nil

      expect(h.member?(:debug)).to be true
      expect(h[:debug]).to be_nil
		end

		it "should take a block that can be used to verify passed values" do
			expect {
				ps = CLI.new do
					option :location, :short => :l
					switch :debug
					switch :verbose
					argument :code
				end.parse!(['-l', 'singapore', '--debug', 'hello']) do |values|
					fail '--debug can not be used with --verbose' if values.debug and values.verbose
				end
			}.not_to raise_error

			out = stderr_read do
				expect {
					ps = CLI.new do
						option :location, :short => :l
						switch :debug
						switch :verbose
						argument :code
					end.parse!(['-l', 'singapore', '--debug', '--verbose', 'hello']) do |values|
						fail '--debug can not be used with --verbose' if values.debug and values.verbose
					end
					}.to raise_error SystemExit
				end
				expect(out).to include('Error: --debug can not be used with --verbose')
				expect(out).to include('Usage:')
		end

		it "should exit displaying usage and error message on standard error on usage error" do
				out = stderr_read do
					expect {
						ps = CLI.new do
							option :weight, :required => true
						end.parse!([])
					}.to raise_error SystemExit
				end
        expect(out).to include('Error: mandatory options not specified: --weight')
        expect(out).to include('Usage:')
		end
	end
end
