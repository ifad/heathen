module Heathen
  module Processors
    class TiffConverter

      MIME_TYPES = [ 'image/tiff' ]

      attr_reader :app

      class << self
        def valid_mime_type?(mime_type)
          return MIME_TYPES.include?(mime_type)
        end
      end

      def initialize(app)
        @app = app
      end

      # return a [ content, meta ] pair, as expcted
      # by dragonfly
      def tiff_to_txt(temp_object, name, args = { } )
        if content = to_txt(temp_object.path)
          [
            content,
            {
                   name: [ temp_object.basename, 'txt' ].join('.'),
                 format: :txt,
              mime_type: "text/plain"
            }
          ]
        else
          raise Heathen::NotConverted.new({
               temp_object: temp_object,
                    action: 'tiff_to_txt',
            original_error: nil
          })
        end
      end

      def tiff_to_html(temp_object)
        if content = to_html(temp_object.path)
          [
            content,
            {
                   name: [ temp_object.basename, 'html' ].join('.'),
                 format: :html,
              mime_type: "text/html"
            }
          ]
        else
          raise Heathen::NotConverted.new({
               temp_object: temp_object,
                    action: 'tiff_to_html',
            original_error: nil
          })
        end
      end

      private

        def to_txt(source)

          tesseract(source, "txt")

        end

        def to_html(source)

          tesseract(source, "html", ["hocr"])

        end

        def tesseract(source, format, params=[])

          executioner = Heathen::Executioner.new(app.converter.log)

          temp_name = app.storage_root + "tmp" + source.split("/").last

          args = [source, temp_name] + params
          executioner.execute('tesseract', *args)

          file = File.open(temp_name.to_s + ".#{format}", "r")
          file.close

          if executioner.last_exit_status == 0
            return file
          else
            file.unlink
            return nil
          end
        end
    end
  end
end
