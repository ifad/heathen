require 'dragonfly'

module Heathen
  module Config
    module App
      module Dragonfly
        def self.configure(app)

          Dir["#{app.root}/processors/**/*.rb"].each { |f| require f }

          ::Dragonfly[:converter].tap do |converter|

            converter.configure_with(:imagemagick)

            converter.configure do |c|
              c.url_format          = '/:job'
              c.log                 = ::Logger.new("#{app.root}/log/converter.log")
              c.content_disposition = :attachment

              define_jobs(c)
            end

            converter.datastore.configure do |c|
              c.root_path = "#{app.storage_root}/file"
            end

            converter.processor.register(::Heathen::Processors::OfficeConverter, app)
            converter.processor.register(::Heathen::Processors::HtmlConverter,   app)
            converter.processor.register(::Heathen::Processors::TiffConverter,  app)

            app.set :converter, converter

            app.set :ooo_port, 8100

            app.configure(:development, :staging) do
              app.set :ooo_host, 'localhost'
            end

            app.configure(:production) do
              app.set :ooo_host, 'digger.ifad.org'
            end

            app.helpers do
              def converter
                settings.converter
              end
            end
          end
        end

        def self.define_jobs(config)
          config.job :image_to_pdf do
            process(:convert, "-quiet -density 72", :pdf)
          end
        end
      end
    end
  end
end
