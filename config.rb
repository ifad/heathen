module Heathen
  module Config
    def self.configure(app)

      app.configure do
        app.set :relative_url_root, (ENV['RACK_RELATIVE_URL_ROOT'] || '')
        app.set :public_folder, Proc.new { File.join(root, "static") }
      end

      app.helpers do
        def relative_url_root
          settings.relative_url_root
        end
      end

      App::Logger.configure(app)
      App::Storage.configure(app)
      App::Cache.configure(app)
      App::Debugger.configure(app)
      App::Redis.configure(app)
      App::Dragonfly.configure(app)
    end
  end
end

Dir[File.expand_path('../config/app/**/*.rb', __FILE__)].each do |f|
  require f
end
