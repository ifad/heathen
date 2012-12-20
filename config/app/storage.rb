module Heathen
  module Config
    module App
      class Storage
        def self.configure(app)
          app.configure :staging, :production do
            app.set :storage_root, '/opt/repofiles/heathen'
          end

          app.configure :development do
            app.set :storage_root, ENV['HEATHEN_STORAGE_ROOT']
          end
        end
      end
    end
  end
end
