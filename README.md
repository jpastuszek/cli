# CLI

Command Line Interface gem allows you to quickly specify command argument parser that will automatically generate usage, handle stdin, switches, options and arguments with default values and value casting.

## Installing

    gem install cli

## Examples

### HTTPClient example

The following example shows basic usage of the CLI gem.
It will use HTTPClient to connect to server that address and port can be specified with `--server` and `--port` switches.
It expects at least one argument specifying the URL (that needs to start with `/`) and optional set of POST arguments.

```ruby
require 'rubygems'
require 'cli'
require 'httpclient'

settings = CLI.new do
    option :server, :description => 'server address', :default => 'www.google.com'
    option :port,	:description => 'server port', :cast => Integer, :default => 80
    argument :url,	:description => 'URL to GET or POST to if arguments are given'
    arguments :post_arguments, :required => false
end.parse! do |settings|
    fail "invalid URL '#{settings.url}', URL has to start with '/'" unless settings.url =~ /^\//
end

c = HTTPClient.new

begin
    if settings.post_arguments.empty?
        puts c.get_async("http://#{settings.server}:#{settings.port}#{settings.url}").pop.content.read
    else
        puts c.post_async("http://#{settings.server}:#{settings.port}#{settings.url}", settings.post_arguments.join("\n")).pop.content.read
    end 
rescue SocketError, Errno::ECONNREFUSED => e
    puts "Falied to connect: #{e}"
end
```

Example usage with default server:

    examples/httpclient /index.html

The output will contain Google website.

Using different server:

    examples/httpclient --server ibm.com /index.html

When run without arguments:

    examples/httpclient

The following message will be printed and the program will exit (status 42):

    Error: mandatory argument 'url' not given
    Usage: httpclient [switches|options] [--] url [post-arguments*]
    Switches:
       --help (-h) - display this help message
    Options:
       --server [www.google.com] - server address
       --port [80] - server port
    Arguments:
       url - URL to GET or POST to if arguments are given
       post-arguments* (optional)

When used with command that does not start with `/`:

    examples/httpclient test

It will print the following message and exit:

    Error: invalid URL 'test', URL has to start with '/'
    Usage: httpclient [switches|options] [--] url [post-arguments*]
    Switches:
       --help (-h) - display this help message
    Options:
       --server [www.google.com] - server address
       --port [80] - server port
    Arguments:
       url - URL to GET or POST to if arguments are given
       post-arguments* (optional)

### Sinatra server example

```ruby
require 'rubygems'
require 'cli'
require 'ip'

settings = CLI.new do
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
sinatra.set :server, settings.server
sinatra.set :lock, true
sinatra.set :boundary, "thumnail image data"
sinatra.set :logging, (not settings.no_logging)
sinatra.set :debug, settings.debug
sinatra.set :optimization, (not settings.no_optimization)
sinatra.set :limit_memory, settings.limit_memory
sinatra.set :limit_map, settings.limit_map
sinatra.set :limit_disk, settings.limit_disk

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
require 'rubygems'
require 'cli'
require 'pathname'
require 'yaml'

settings = CLI.new do
	description 'Generate blog posts in given Jekyll directory from input statistics'
	stdin :log_data,        :cast => YAML, :description => 'statistic data in YAML format'
	option :location,       :short => :l, :description => 'location name (ex. Dublin, Singapore, Califorina)'
	option :csv_dir,        :short => :c, :cast => Pathname, :default => 'csv', :description => 'directory name where CSV file will be storred (relative to jekyll-dir)'
	argument :jekyll_dir,   :cast => Pathname, :default => '/var/lib/vhs/jekyll', :description => 'directory where site source is located'
end.parse! do |settings|
	fail 'jekyll-dir is not a directory' unless settings.jekyll_dir.directory?
	fail '--csv-dir is not a directory (relative to jekyll-dir)' unless (settings.jekyll_dir + settings.csv_dir).directory?
end

p settings

# do your stuff
```

Example help message:

    Usage: processor [switches|options] [--] [jekyll-dir] < log-data
    Generate blog posts in given Jekyll directory from input statistics
    Input:
       log-data - statistic data in YAML format
    Switches:
       --help (-h) - display this help message
    Options:
       --location (-l) - location name (ex. Dublin, Singapore, Califorina)
       --csv-dir (-c) [csv] - directory name where CSV file will be storred (relative to jekyll-dir)
    Arguments:
       jekyll-dir [/var/lib/vhs/jekyll] - directory where site source is located

With this example usage (assuming /var/lib/vhs/jekyll/csv dir exist):

    examples/processor --location Singapore <<EOF
    :parser: 
      :successes: 41
      :failures: 0
    EOF

The `settings` variable will contain:

    #<CLI::Values stdin={:parser=>{:successes=>41, :failures=>0}}, jekyll_dir=#<Pathname:/var/lib/vhs/jekyll>, csv_dir=#<Pathname:csv>, help=nil, location="Singapore">

Output if jekyll-dir does not exist:

    Error: jekyll-dir is not a directory
    Usage: processor [switches|options] [--] [jekyll-dir] < log-data
    Generate blog posts in given Jekyll directory from input statistics
    Input:
       log-data - statistic data in YAML format
    Switches:
       --help (-h) - display this help message
    Options:
       --location (-l) - location name (ex. Dublin, Singapore, Califorina)
       --csv-dir (-c) [csv] - directory name where CSV file will be storred (relative to jekyll-dir)
    Arguments:
       jekyll-dir [/var/lib/vhs/jekyll] - directory where site source is located

### Ls like utility

`arguments` specifier can be used to match multiple arguments.
The `arguments` specifier matched value will always be an array of casted elements.
Default and mandatory arguments will have priority on matching values (see specs for examples).

`options` specifier can be used to allow specifing same option multiple times.
The `options` specifier matched value will always be an array of casted elements or empty if option not specified.

```ruby
require 'rubygems'
require 'cli'
require 'pathname'

settings = CLI.new do
	description 'Lists content of directories'
	switch :long, :short => :l, :description => 'use long listing'
	options :exclude, :short => :e, :description => 'exclude files from listing'
	arguments :directories, :cast => Pathname, :default => '.', :description => 'directories to list content of'
end.parse!

settings.directories.each do |dir|
	next unless dir.directory?
	dir.each_entry do |e|
		next if e.to_s == '.' or e.to_s == '..'
		e = dir + e
		next if settings.exclude.include? e.to_s
		if settings.long
			puts "#{e.stat.uid}:#{e.stat.gid} #{e}"
		else
			puts e
		end
	end
end
```

Example help message:

    Usage: ls [switches|options] [--] [directories*]
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
    
## Usage

`CLI.new` takes a block where you specify parser behavior. The returned object is a parser that has `#parse` and `#parse!` methods.

### `#parse` method

It will take argument array (defaults to ARGV), standard input IO (defaults to STDIO) and standard error IO (defaults to STDERR).

The method will parse argument array and cast standard input IO according to parser specification and return OpenStruct kind of object with resulting values.

The returned object will have `help` attribute set if `--help` or `-h` switch was found in argument array or `version` attribute if `--version` argument was found. 
In other case all the attributes will be set to appropriate values depending on argument array and parser specification.
In case of parsing error `CLI::ParsingError` kind of exception will be raised.

### `#parse!` method

This is higher level version of `#parse` method that will exit the program and print out usage if there was parsing error. Also it will display usage on `--help` or `-h` switch and version string on `--version` switch found in argument array.

In other case it will return OpenStruct object from `#parse` method.

Additionally this method can be called with a block that will get the OpenStruct like object before returning it. This block should contain additional value verifications and if it raises RuntimeError (via `fail` method for instance) the error message will be displayed followed by usage and the program will exit.

### Parser behavior specifiers

#### description 'string'
The *string* will be displayed in usage output as your program short description.

#### version 'string'
The *string* representing program version that will be displayed when `--version` switch is used

#### switch :name [, options hash]

When switch is specified in the command argument list the object returned by `#parse` or `#parse!` will contain argument of same name set to `true`. Otherwise the argument value will be `nil`.

*:name* should be a symbol that will map to long switch (`--name`) where underscore (`_`) will be replaced with minus (`-`). Name has to be unique.

Option hash can contain following pairs:

* **:short => :symbol** - where *:symbol* is a single letter symbol that will represent short switch name (`-n`). Short name has to be unique.
* **:description => 'string'** - switch description string that will be displayed in the usage output

#### option :name [, options hash]

Same as *switch* but additionally it has to be followed by a value on the command argument list.
The value after casting (if used) will be available from the `#parse` or `#parse!` returned object as argument of the same name.

In addition to *switch*, option hash can have following pairs:

* **:default => value** - use default value of *value* if the option was not specified on the command argument list. The *value* will firstly be casted to string (with `#to_s`) and then it will be casted if casting is specified.
* **:default_label => label** - display *label* in usage rather than default value - useful to descirbe default value if default value is generated if no value is provided
* **:cast => cast specifier** - cast the provided value (or default) with given *cast specifier*. 
The specifier can be a class constant - the value will be provided to `#new` method of the class and resulting object used as option value. When provided constant does not respond to `#new` (i.e. it is a module) the `#load` method will be tried instead. If provided specifier is a Proc (or `lambda {}`) the Proc will be called with the value and resulting value will be used. Otherwise `CLI::ParsingError::CastError` will be raised.  Special cast specified `Integer` or `Float` can also be used - the value will be strictly casted to integer or float type.
* **:required => true** - if used and no *default* value is specified the `#parse` method will fail with `CLI::ParsingError::MissingOptionValueError` if the option was not specified in the command argument list. If `#parse!` method was used the program will exit with appropriate message.

#### options :name [, options hash]

Same as *option* but can be specified multiple times in the command argument list.
The resulting `#parse` or `#parse!` returned object will contain an argument with the same name that will always be an array.
The array may be empty if the option was not used and *required* option was not set, otherwise it will contain casted values in order of specification in the command argument list.

#### argument :name [,options hash]

After the parser encounters command line argument that is not a *switch* or *option* or it is literally `--` string it will start matching arguments.

Each argument will be matched to argument specifications in order and their value after optional casting will be available as `#parse` or `#parse!` returned object argument with the same name.

Options hash can contain the same pairs as *option* expect of **:short => :symbol**. 

If defaults are used the parser will keep using default values until it has enough command line arguments available to fill all mandatory arguments.
Arguments are required by default, use **:required => false** option pair to use `nil` value if argument is not specified on the command line argument list.

#### arguments :name [,options hash]

Same as *argument* but will match one or more arguments and provide them in array of casted values.
If argument is not required and not specified in command argument list then its value will be an empty array.

When used with *argument* specifiers that use default values the parser will try to assign at least one value to this specifier, but not more values so that all mandatory (that have no default and are required) arguments will be assigned.

#### stdin :name, [options hash]

Used once to specify that stdin should be handled.
When used the `#parse` or `#parse!` returned object will have `stdin` argument that by default will contain stdin IO object.

As with *switch* specifier the **:description => 'string'** can be used.
Also **:cast => cast specifier** option pair can be used but the value will be an IO object and not string.

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

