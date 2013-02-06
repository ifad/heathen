module Heathen
  module Encoders
    class ImageEncoder < Base

      MIME_TYPES = [ 'image/tiff' ]

      def encode(temp_object, format, args='')
        details = identify(temp_object)

        if details[:format] == :tiff
          executioner = Heathen::Executioner.new(app.converter.log)
          executioner.execute("exiv2", '-M', "del Exif.Image.XPTitle", '-M', "del Exif.Image.XPComment", temp_object.path)
        end

        temp_object
      end

    end
  end
end
