require 'rack/cache'

module Heathen
  module Config
    module App
      class Cache
        def self.configure(app)
          app.configure :production do
            app.use Rack::Cache, {
              :verbose     => false,
              :metastore   => URI.encode("file:#{app.storage_root}/cache/meta"),
              :entitystore => URI.encode("file:#{app.storage_root}/cache/body")
            }
          end

          app.configure :development, :staging do
            app.use Rack::Cache, {
              :verbose     => true,
              :metastore   => URI.encode("file:#{app.storage_root}/cache/meta"),
              :entitystore => URI.encode("file:#{app.storage_root}/cache/body")
            }
          end
        end
      end
    end
  end
end
