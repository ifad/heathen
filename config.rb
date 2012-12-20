module Heathen
  module Config
    def self.configure(app)
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
