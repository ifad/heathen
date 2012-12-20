module Heathen
  module Config
    module App
      module Logger
         def self.configure(app)
           app.configure :staging, :development do
             app.enable :logging
             app.use Rack::CommonLogger
           end
         end
      end
    end
  end
end
