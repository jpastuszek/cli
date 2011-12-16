require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

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
			ps = CLI.new.parse
			ps.stdin.should be_nil
		end

		it "should return IO if stdin is defined" do
			ps = CLI.new do
				stdin
			end.parse
			ps.stdin.should be_a IO
		end

		it "should support casting" do
			ps = nil
			ss = CLI.new do
				stdin :log_data, :cast => YAML, :description => 'log statistic data in YAML format'
			end

			stdin_write(@yaml) do
				ps = ss.parse
			end

			ps.stdin.should == {:parser=>{:successes=>41, :failures=>0}}
		end
	end
end

