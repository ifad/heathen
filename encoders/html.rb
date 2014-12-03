module Heathen
  module Encoders
    class Html < Base

      include Concerns::Wkhtmltopdf

      MIME_TYPES = [ 'text/html' ]

      # return a [ content, meta ] pair, as expcted
      # by dragonfly
      def encode(temp_object, format, args = { })

        unless format == :pdf && self.class.valid_mime_type?(temp_object.meta[:mime_type])
          throw :unable_to_handle
        end

        if content = wkhtmltopdf(temp_object.path)
          [ content, meta(temp_object, :pdf, 'application/pdf') ]
        else
          raise Heathen::NotConverted.new({
               temp_object: temp_object,
                    action: 'html_to_pdf',
                   command: executioner.last_command,
            original_error: executioner.last_messages
          })
        end
      end
    end
  end
end

