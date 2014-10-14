require 'dragonfly'

module Dragonfly
  module ImageMagick
    module Utils

      private
        def convert(temp_object=nil, args='', format=nil)
          byebug
          tempfile = new_tempfile(format)
          run convert_command, %(#{args} #{quote(temp_object.path) if temp_object} #{quote(tempfile.path)})
          tempfile
        end
    end
  end
end

module Heathen
  module Config
    module App
      module Dragonfly
        def self.configure(app)

          require "#{app.root}/encoders/base"
          require "#{app.root}/processors/base"

          Dir["#{app.root}/encoders/**/*.rb"].each   { |f| require f }
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
              c.root_path = app.file_storage_root.to_s
            end

            converter.encoder.register(::Heathen::Encoders::Pdf,    app)
            converter.encoder.register(::Heathen::Encoders::Office, app)
            converter.encoder.register(::Heathen::Encoders::Html,   app)
            converter.encoder.register(::Heathen::Encoders::Url,    app)
            converter.encoder.register(::Heathen::Encoders::Ocr,    app)
            converter.encoder.register(::Heathen::Encoders::Libre,  app)

            converter.processor.register(::Heathen::Processors::Ocr, app)

            app.set :converter, converter

            app.set :ooo_port, ENV['OOO_PORT'] || 8100
            app.set :ooo_host, ENV['OOO_HOST'] || 'localhost'

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

          config.job :doc do
            encode(:doc)
          end

          config.job :ocr do
            process(:convert, '-colorspace Gray -depth 1 -density 400 -background white +matte', 'tiff')
            process(:ocr)
            encode(:pdf)
          end
        end
      end
    end
  end
end
