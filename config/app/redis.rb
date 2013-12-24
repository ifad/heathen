require 'redis'
require 'redis-namespace'

module Heathen
  module Config
    module App
      module Redis
        def self.configure(app)

          app.set :redis, ::Redis::Namespace.new(:heathen, redis:
            ::Redis.new(host: ENV['REDIS_HOST'], port: ENV['REDIS_PORT'], password: ENV['REDIS_PASSWORD']))

          app.helpers do
            def redis
              settings.redis
            end
          end
        end
      end
    end
  end
end
