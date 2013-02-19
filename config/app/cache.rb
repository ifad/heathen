require 'rack/cache'

module Heathen
  module Config
    module App
      class Cache
        def self.configure(app)
          app.configure :production do
            app.use Rack::Cache, {
              :verbose     => false,
              :metastore   => URI.encode("file:#{app.cache_storage_root}/meta"),
              :entitystore => URI.encode("file:#{app.cache_storage_root}/body")
            }
          end

          app.configure :development, :staging do
            app.use Rack::Cache, {
              :verbose     => true,
              :metastore   => URI.encode("file:#{app.cache_storage_root}/meta"),
              :entitystore => URI.encode("file:#{app.cache_storage_root}/body")
            }
          end
        end
      end
    end
  end
end
