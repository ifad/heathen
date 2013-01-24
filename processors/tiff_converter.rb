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
      def tiff_to_txt(temp_object)
        if content = to_txt(temp_object.path)
          [
            content,
            {
              name:      [ temp_object.basename, 'txt' ].join('.'),
              format:    :txt,
              mime_type: "text/plain"
            }
          ]
        else
          raise Heathen::NotConverted.new({
            temp_object:    temp_object,
            action:         'tiff_to_txt',
            original_error: nil
          })
        end
      end

      private

        # returns a Tempfile instance.
        # calling method is responsible for closing/unlinking
        def to_txt(source)

          executioner = Heathen::Executioner.new(app.converter.log)

          temp_name = app.storage_root + "tmp" + source.split("/").last

          executioner.execute('tesseract', source, temp_name, "hocr")

          file = File.open(temp_name.to_s + ".txt", "r")
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
