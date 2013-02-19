module Heathen
  module Encoders
    class HtmlConverter < Base

      MIME_TYPES = [ 'text/html' ]

      class << self
        def encodes?(job)
          valid_mime_type?(job.mime_type)
        end
      end

      # return a [ content, meta ] pair, as expcted
      # by dragonfly
      def encode(temp_object, format, args = { })

        unless format == :pdf && self.class.valid_mime_type?(temp_object.meta[:mime_type])
          throw :unable_to_handle
        end

        if content = PDFKit.new(temp_object.data).to_pdf
          [ content, meta(temp_object, :pdf, 'application/pdf') ]
        else
          raise Heathen::NotConverted.new({
               temp_object: temp_object,
                    action: 'html_to_pdf',
            original_error: nil
          })
        end
      end
    end
  end
end

