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

          FileUtils.mkdir_p app.storage_root + "tmp"
        end
      end
    end
  end
end
