require 'dragonfly'

Dir[File.expand_path('../../processors/**/*.rb', __FILE__)].each { |f| require f }

module Heathen
  module Config
    module Dragonfly

      def self.configure(app)
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
