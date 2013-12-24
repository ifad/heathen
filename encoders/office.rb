require 'encoders/common'

module Heathen
  module Encoders
    class Office < Base

      include Heathen::Encoders::Common

      MIME_TYPES = [
        'application/zip', # For DOCX files.
        'application/msword',
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        'application/vnd.ms-excel',
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        'application/vnd.ms-powerpoint',
        'application/vnd.openxmlformats-officedocument.presentationml.presentation'
      ]

      # return a [ content, meta ] pair, as expcted
      # by dragonfly
      def encode(temp_object, format, args = { })

        unless format == :pdf && self.class.valid_mime_type?(temp_object.meta[:mime_type])
          throw :unable_to_handle
        end

        if content = libreoffice(temp_object.path, :pdf)
          [ content, meta(temp_object, :pdf, 'application/pdf') ]
        else
          raise Heathen::NotConverted.new({
               temp_object: temp_object,
                    action: 'office_to_pdf',
            original_error: nil
          })
        end
      end
    end
  end
end
