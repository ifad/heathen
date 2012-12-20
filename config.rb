module Heathen
  module Config
    def self.configure(app)
      Logger.configure(app)
      Storage.configure(app)
      Cache.configure(app)
      Debugger.configure(app)
      Redis.configure(app)
      Dragonfly.configure(app)
    end
  end
end

Dir[File.expand_path('../config/**/*.rb', __FILE__)].each { |f| require f }
