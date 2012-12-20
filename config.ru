require 'rubygems'
require 'bundler'

Bundler.require(:default, ENV['RACK_ENV'].to_sym)

require File.expand_path('../app', __FILE__)

disable :run

map(ENV['RACK_RELATIVE_URL_ROOT'] || '/') do
  run Heathen::App
end
