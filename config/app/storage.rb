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

          app.set :file_storage_root,  app.storage_root + "file"
          app.set :cache_storage_root, app.storage_root + "cache"
          app.set :temp_storage_root,  app.storage_root + "tmp"

          [ :storage_root, :file_storage_root, :cache_storage_root, :temp_storage_root ].each do |setting|
            FileUtils.mkdir_p(app.send(setting))
          end
        end
      end
    end
  end
end
