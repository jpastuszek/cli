$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rspec'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|
  
end

def stdin_write(data)
		r, w = IO.pipe
		old_stdin = STDIN.clone
		STDIN.reopen r
		Thread.new do
		 	w.write data
			w.close
		end
		begin
			yield
		ensure
			STDIN.reopen old_stdin
		end
end

def stdout_read
		r, w = IO.pipe
		old_stdout = STDOUT.clone
		STDOUT.reopen(w)
		data = ''
		t = Thread.new do
			data << r.read
		end
		begin
			yield
		ensure
			w.close
			STDOUT.reopen(old_stdout)
		end
		t.join
		data
end

def stderr_read
		r, w = IO.pipe
		old_stdout = STDERR.clone
		STDERR.reopen(w)
		data = ''
		t = Thread.new do
			data << r.read
		end
		begin
			yield
		ensure
			w.close
			STDERR.reopen(old_stdout)
		end
		t.join
		data
end

require 'cli'

