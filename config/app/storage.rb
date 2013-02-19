require 'pathname'

module Heathen
  module Config
    module App
      class Storage
        def self.configure(app)
          app.configure :staging, :production do
            app.set :storage_root, Pathname.new('/opt/repofiles/heathen')
          end

          app.configure :development do
            app.set :storage_root, Pathname.new(ENV['HEATHEN_STORAGE_ROOT'])
          end

          app.set :cache_storage_root, app.storage_root + "cache"

          FileUtils.mkdir_p app.storage_root
        end
      end
    end
  end
end
