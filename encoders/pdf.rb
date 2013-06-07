module Heathen
  module Encoders
    class Pdf < Base

      MIME_TYPES = [
        'application/pdf'
      ]

      def encode(temp_object, format, args = { })
        unless format == :pdf && self.class.valid_mime_type?(temp_object.meta[:mime_type])
          throw :unable_to_handle
        end

        # just return the original file
        [ temp_object.tempfile, meta(temp_object, :pdf, 'application/pdf') ]
      end
    end
  end
end
