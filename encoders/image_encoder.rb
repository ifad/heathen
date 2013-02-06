module Heathen
  module Encoders
    class ImageEncoder < Base

      MIME_TYPES = [ 'image/tiff' ]

      def encode(temp_object, format, args='')
        details = identify(temp_object)

        if details[:format] != :tiff
          process(:convert, "-quiet -density 72 -depth 4", :tiff)
        end
      end

    end
  end
end
