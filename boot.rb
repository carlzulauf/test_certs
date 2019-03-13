PROJECT_ROOT = File.dirname File.expand_path(__FILE__)
$LOAD_PATH.unshift File.join(PROJECT_ROOT, "lib")

require 'fileutils'
require 'pstore'
require 'bundler/setup'
Bundler.require(:default)

require 'authority'
