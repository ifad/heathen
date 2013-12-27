module Heathen
  module Encoders
    class Libre < Base

      include Concerns::Libreoffice

      MIME_TYPES = [
        'application/zip', # For ODT files.
        'application/vnd.oasis.opendocument.text'
      ]

      # return a [ content, meta ] pair, as expcted
      # by dragonfly
      def encode(temp_object, format, args = { })

        unless [ :pdf, :doc ].include?(format) && self.class.valid_mime_type?(temp_object.meta[:mime_type])
          throw :unable_to_handle
        end

        if content = libreoffice(temp_object.path, format)
          [ content, meta(temp_object, format, mime_for(format)) ]
        else
          raise Heathen::NotConverted.new({
               temp_object: temp_object,
                    action: "odt_to_#{format}",
                   command: executioner.last_command,
            original_error: executioner.last_messages
          })
        end
      end

      private
        def mime_for(format)
          case format
            when :pdf then 'application/pdf'
            when :doc then 'application/msword'
          end
        end
    end
  end
end
