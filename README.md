# CLI

Command Line Interface gem allows you to quickly specify command argument parser that will automatically handle usage rendering, casting, default values and other stuff for you.

CLI supports following specifiers:

* switch - (`--verbose` or `-v`) binary operators, by default set to nil, when specified set to true
* option - (`--name John` or `-n John`) switches that take value; default value can be specified, otherwise defaults to nil
* options - (`-n John -n Frank`) like option but can be used multiple times on command line; default value or array of values can be given, otherwise defaults to empty array
* argument - (`John`) capture single command; default value can be specified; raises error if not given
* arguments - (`John Frank`) capture multiple command arguments; defaults to empty array
* stdin - if standard input is to be handled it can be mentioned in usage output; also stdin data casting is supported

Each element can have description that will be visible in the usage output.

See examples and specs for more info.

## Installing

    gem install cli

## Usage

### Sinatra server example

```ruby
require 'cli'
require 'ip'

options = CLI.new do
	description 'Example CLI usage for Sinatra server application'
	version "1.0.0"
	switch :no_bind,			:description => "Do not bind to TCP socket - useful with -s fastcgi option"
	switch :no_logging,			:description => "Disable logging"
	switch :debug,				:description => "Enable debugging"
	switch :no_optimization,	:description => "Disable size hinting and related optimization (loading, prescaling)"
	option :bind,				:short => :b, :default => '127.0.0.1', :cast => IP, :description => "HTTP server bind address - use 0.0.0.0 to bind to all interfaces"
	option :port,				:short => :p, :default => 3100, :cast => Integer, :description => "HTTP server TCP port"
	option :server,				:short => :s, :default => 'mongrel', :description => "Rack server handler like thin, mongrel, webrick, fastcgi etc."
	option :limit_memory,		:default => 128*1024**2, :cast => Integer, :description => "Image cache heap memory size limit in bytes"
	option :limit_map,			:default => 256*1024**2, :cast => Integer, :description => "Image cache memory mapped file size limit in bytes - used when heap memory limit is used up"
	option :limit_disk,			:default => 0, :cast => Integer, :description => "Image cache temporary file size limit in bytes - used when memory mapped file limit is used up"
end.parse!

# use to set sinatra settings
require 'sinatra/base'

sinatra = Sinatra.new

sinatra.set :environment, 'production'
sinatra.set :server, options.server
sinatra.set :lock, true
sinatra.set :boundary, "thumnail image data"
sinatra.set :logging, (not options.no_logging)
sinatra.set :debug, options.debug
sinatra.set :optimization, (not options.no_optimization)
sinatra.set :limit_memory, options.limit_memory
sinatra.set :limit_map, options.limit_map
sinatra.set :limit_disk, options.limit_disk

# set up your application

sinatra.run!
```

To see help message use `--help` or `-h` anywhere on the command line:

    examples/sinatra --help

Example help message:

    Usage: sinatra [switches|options]
    Example CLI usage for Sinatra server application
    Switches:
       --no-bind - Do not bind to TCP socket - useful with -s fastcgi option
       --no-logging - Disable logging
       --debug - Enable debugging
       --no-optimization - Disable size hinting and related optimization (loading, prescaling)
       --help (-h) - display this help message
       --version - display version string
    Options:
       --bind (-b) [127.0.0.1] - HTTP server bind address - use 0.0.0.0 to bind to all interfaces
       --port (-p) [3100] - HTTP server TCP port
       --server (-s) [mongrel] - Rack server handler like thin, mongrel, webrick, fastcgi etc.
       --limit-memory [134217728] - Image cache heap memory size limit in bytes
       --limit-map [268435456] - Image cache memory mapped file size limit in bytes - used when heap memory limit is used up
       --limit-disk [0] - Image cache temporary file size limit in bytes - used when memory mapped file limit is used up

To see version string use `--version`

    examples/sinatra --version

Example version output:

    sinatra version "0.0.4"

### Statistic data processor example

```ruby
require 'cli'
require 'pathname'
require 'yaml'

options = CLI.new do
	description 'Generate blog posts in given Jekyll directory from input statistics'
	stdin :log_data,		:cast => YAML, :description => 'statistic data in YAML format'
	option :location,		:short => :l, :description => 'location name (ex. Dublin, Singapore, Califorina)'
	option :csv_dir,		:short => :c, :cast => Pathname, :default => 'csv', :description => 'directory name where CSV file will be storred (relative to jekyll-dir)'
	argument :jekyll_dir,	:cast => Pathname, :default => '/var/lib/vhs/jekyll', :description => 'directory where site source is located'
end.parse!

# do your stuff
```

Example help message:

    Usage: processor [switches|options] [--] jekyll-dir < log-data
    Generate blog posts in given Jekyll directory from input statistics
    Input:
       log-data - statistic data in YAML format
    Switches:
       --help (-h) - display this help message
    Options:
       --location (-l) - location name (ex. Dublin, Singapore, Califorina)
       --csv-dir (-c) [csv] - directory name where CSV file will be storred (relative to jekyll-dir)
    Arguments:
       jekyll-dir - directory where site source is located

With this example usage:

    examples/processor --location Singapore <<EOF
    :parser: 
      :successes: 41
      :failures: 0
    EOF

The `options` variable will contain:

    #<CLI::Values stdin={:parser=>{:successes=>41, :failures=>0}}, jekyll_dir=#<Pathname:/var/lib/vhs/jekyll>, csv_dir=#<Pathname:csv>, help=nil, location="Singapore">

### Ls like utility

`arguments` specifier can be used to match multiple arguments.
The `arguments` specifier matched value will always be an array of casted elements.
Default and mandatory arguments will have priority on matching values (see specs for examples).

`options` specifier can be used to allow specifing same option multiple times.
The `options` specifier matched value will always be an array of casted elements or empty if option not specified.

```ruby
require 'cli'
require 'pathname'

values = CLI.new do
	description 'Lists content of directories'
	switch :long, :short => :l, :description => 'use long listing'
	options :exclude, :short => :e, :description => 'exclude files from listing'
	arguments :directories, :cast => Pathname, :default => '.', :description => 'directories to list content of'
end.parse!

values.directories.each do |dir|
	next unless dir.directory?
	dir.each_entry do |e|
		next if e.to_s == '.' or e.to_s == '..'
		e = dir + e
		next if values.exclude.include? e.to_s
		if values.long
			puts "#{e.stat.uid}:#{e.stat.gid} #{e}"
		else
			puts e
		end
	end
end
```

Example help message:

    Usage: ls [switches|options] [--] directories*
    Lists content of directories
    Switches:
       --long (-l) - use long listing
       --help (-h) - display this help message
    Options:
       --exclude* (-e) - exclude files from listing
    Arguments:
       directories* [.] - directories to list content of

Example usage:

    examples/ls

Prints:

    .document
    .git
    .gitignore
    .README.md.swp
    .rspec
    cli.gemspec
    examples
    features
    ...

Excluding .git and .gitignore:

    examples/ls -e .git -e .gitignore

Prints:

    .document
    .README.md.swp
    .rspec
    cli.gemspec
    examples
    features
    ...

With directory list:
    
    examples/ls *

Prints:

    examples/.ls.swp
    examples/ls
    examples/processor
    examples/sinatra
    features/cli.feature
    features/step_definitions
    features/support
    lib/cli
    lib/cli.rb
    pkg/cli-0.0.1.gem
    pkg/cli-0.0.2.gem
    ...
    
Long printout:

    examples/ls -l *

Prints:

    501:20 examples/.ls.swp
    501:20 examples/ls
    501:20 examples/processor
    501:20 examples/sinatra
    501:20 features/cli.feature
    501:20 features/step_definitions
    501:20 features/support
    501:20 lib/cli
    501:20 lib/cli.rb
    501:20 pkg/cli-0.0.1.gem
    501:20 pkg/cli-0.0.2.gem
    ...
    
## Contributing to CLI
 
* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it
* Fork the project
* Start a feature/bugfix branch
* Commit and push until you are happy with your contribution
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

## Copyright

Copyright (c) 2011 Jakub Pastuszek. See LICENSE.txt for
further details.

