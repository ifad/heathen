require 'dragonfly'

module Heathen
  module Config
    module App
      module Dragonfly
        def self.configure(app)

          require "#{app.root}/encoders/base"
          Dir["#{app.root}/encoders/**/*.rb"].each { |f| require f }

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

            converter.encoder.register(::Heathen::Encoders::OfficeConverter, app)
            converter.encoder.register(::Heathen::Encoders::HtmlConverter,   app)
            converter.encoder.register(::Heathen::Encoders::UrlConverter,    app)
            converter.encoder.register(::Heathen::Encoders::TiffConverter,   app)

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
            encode(:pdf, "-quiet -density 72")
          end

          config.job :ocr do |args|
            encode(:tiff)
            process(:tiff_split)
            process(:tiff_to_html, args)
            process(:tiff_to_pdf)
          end
        end
      end
    end
  end
end
