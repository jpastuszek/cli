require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'yaml'

describe CLI do
	describe 'STDIN handling' do
		before :all do
			@yaml = <<EOF
---
:parser:
  :successes: 41
  :failures: 0
EOF
		end

		it "should be nil if not specified" do
			ps = CLI.new.parse([])
      expect(ps.stdin).to be_nil
		end

		it "should return IO if stdin is defined" do
			ps = CLI.new do
				stdin
			end.parse([])
      expect(ps.stdin).to be_a IO
		end

		it "should support casting to module responding to load" do
			ps = nil
			ss = CLI.new do
				stdin :log_data, :cast => YAML, :description => 'log statistic data in YAML format'
			end

			stdin_write(@yaml) do
				ps = ss.parse([])
			end

      expect(ps.stdin).to eq({:parser=>{:successes=>41, :failures=>0}})
		end

		it "should support casting with lambda" do
			ps = nil
			ss = CLI.new do
				stdin :log_data, :cast => lambda{|sin| sin.read.upcase}, :description => 'log statistic data in YAML format'
			end

			stdin_write('hello world') do
				ps = ss.parse([])
			end

      expect(ps.stdin).to eq 'HELLO WORLD'
		end

		it "should support casting with custom class" do
			class Upcaser
				def initialize(io)
					@value = io.read.upcase
				end
				attr_reader :value
			end

			ps = nil
			ss = CLI.new do
				stdin :log_data, :cast => Upcaser, :description => 'log statistic data in YAML format'
			end

			stdin_write('hello world') do
				ps = ss.parse([])
			end

      expect(ps.stdin).to be_a Upcaser
      expect(ps.stdin.value).to eq 'HELLO WORLD'
		end
	end
end
