module Heathen
  module Config
    module App
      module Debugger
        def self.configure(app)
          app.configure :development do
            debugger = if RUBY_PLATFORM == 'java'
              'ruby-debug'
            else
              RUBY_VERSION.to_f >= 2.0 ? 'byebug' : 'debugger'
            end

            require debugger
          end
        end
      end
    end
  end
end
