# CLI

Command Line Interface gem allows you to quickly specify command argument parser that will automatically handle usage rendering, casting, default values and other stuff for you.

CLI supports specifying:
* switches - (--name or -n) binary operators, by default set to nil and when specified set to true
* options - (--name John or -n John) switches that take value; default value can be given, otherwise default to nil
* arguments - (John) capture command arguments that are not switches
* stdin - if standard input is to be handled it can be mentioned in usage output; also stdin data casting is supported

Each element can have description that will be visible in the usage output.

See examples and specs for more info.

## Installing

    gem install cli

## Usage

Sinatra server example:

    require 'cli'
    require 'ip'
    
    options = CLI.new do
    	description 'Example CLI usage for Sinatra server application'
    	version (cli_root + 'VERSION').read
    	switch :no_bind,					:description => "Do not bind to TCP socket - useful with -s fastcgi option"
    	switch :no_logging,				:description => "Disable logging"
    	switch :debug,						:description => "Enable debugging"
    	switch :no_optimization,	:description => "Disable size hinting and related optimization (loading, prescaling)"
    	option :bind,							:short => :b, :default => '127.0.0.1', :cast => IP, :description => "HTTP server bind address - use 0.0.0.0 to bind to all interfaces"
    	option :port,							:short => :p, :default => 3100, :cast => Integer, :description => "HTTP server TCP port"
    	option :server,						:short => :s, :default => 'mongrel', :description => "Rack server handler like thin, mongrel, webrick, fastcgi etc."
    	option :limit_memory,			:default => 128*1024**2, :cast => Integer, :description => "Image cache heap memory size limit in bytes"
    	option :limit_map,				:default => 256*1024**2, :cast => Integer, :description => "Image cache memory mapped file size limit in bytes - used when heap memory limit is used up"
    	option :limit_disk,				:default => 0, :cast => Integer, :description => "Image cache temporary file size limit in bytes - used when memory mapped file limit is used up"
    end.parse!
    
    p options
    
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

