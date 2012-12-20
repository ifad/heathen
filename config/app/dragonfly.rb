require 'dragonfly'

module Heathen
  module Config
    module App
      module Dragonfly
        def self.configure(app)

          Dir["#{app.root}/processors/**/*.rb"].each { |f| require f }

          ::Dragonfly[:converter].tap do |converter|
            converter.configure do |c|
              c.url_format          = '/:job'
              c.log                 = ::Logger.new("#{app.root}/log/converter.log")
              c.content_disposition = :attachment
            end

            converter.datastore.configure do |c|
              c.root_path = "#{app.storage_root}/file"
            end

            converter.processor.register(::Heathen::Processors::OfficeConverter, app)

            app.set :converter, converter

            app.helpers do
              def converter
                settings.converter
              end
            end
          end
        end
      end
    end
  end
end
