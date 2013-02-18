#!/usr/bin/env rake

ENV['RACK_ENV']               ||= "development"
ENV['HEATHEN_STORAGE_ROOT']   ||= File.expand_path('../storage', __FILE__)
ENV['RACK_RELATIVE_URL_ROOT'] ||= '/heathen'

require ($app = File.expand_path('../app', __FILE__))

namespace :heathen do

  namespace :redis do
    desc "Clean the redis database keys"
    task :clean do
      redis = Heathen::App.redis
      redis.keys.each{ |k| redis.del(k) }
    end
  end

  desc "Run a console"
  task :console do
    exec "irb -r #{$app}"
  end
end

