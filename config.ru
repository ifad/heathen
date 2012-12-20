require 'rubygems'
require 'bundler'

Bundler.require(:default, ENV['RACK_ENV'])

require File.expand_path('../app', __FILE__)

run Heathen::App
