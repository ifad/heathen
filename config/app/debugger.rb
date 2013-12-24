module Heathen
  module Config
    module App
      module Debugger
        def self.configure(app)
          app.configure :development do
            require RUBY_VERSION.to_f >= 2.0 ? 'byebug' : 'debugger'
          end
        end
      end
    end
  end
end
