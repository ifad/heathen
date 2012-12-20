module Heathen
  module Config
    module Debugger
      def self.configure(app)
        app.configure :development do
          require 'debugger'
          # ::Debugger.start_remote
        end
      end
    end
  end
end
