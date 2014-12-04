module Heathen
  module Config
    module App
      class Wkhtmltopdf
        def self.configure(app)
          app.set :wkhtmltopdf, ENV['WKHTMLTOPDF'] || 'wkhtmltopdf'
        end
      end
    end
  end
end
