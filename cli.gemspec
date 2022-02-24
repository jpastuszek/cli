Gem::Specification.new do |spec|
  require 'bundler'
  # spec is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  spec.name = "cli"
  spec.version = "1.4.0"
  spec.homepage = "http://github.com/jpastuszek/cli"
  spec.license = "MIT"
  spec.summary = %Q{Command line argument parser with stdin handling and usage generator}
  spec.description = %Q{Command Line Interface gem allows you to quickly specify command argument parser that will automatically generate usage, handle stdin, switches, options and arguments with default values and value casting}
  spec.email = "jpastuszek@protonmail.com"
  spec.authors = ["Jakub Pastuszek"]

  spec.files         = Dir['**/**'].grep_v(/.gem$/)
  spec.require_paths = ["lib"]

  Bundler.require(:default, :development)
end
