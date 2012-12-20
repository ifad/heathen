require 'redis'
require 'redis-namespace'

module Heathen
  module Config
    module App
      module Redis
        def self.configure(app)
          app.configure(:production) do
            app.set :redis, ::Redis::Namespace.new(:heathen, ::Redis.new(host: 'persist.ifad.org', port: 6383, password: ENV['REDIS_PASSWORD']))
          end

          app.configure(:staging) do
            app.set :redis, ::Redis::Namespace.new(:heathen, ::Redis.new(host: 'store.ifad.org', port: 6383, password: ENV['REDIS_PASSWORD']))
          end

          app.configure(:development) do
            app.set :redis, ::Redis::Namespace.new(:heathen, ::Redis.new)
          end

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
