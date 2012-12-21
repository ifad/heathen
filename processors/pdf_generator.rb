module Heathen
  module Processors
    class HtmlConverter

      MIME_TYPES = %{
        text/html
      }

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
      def html_to_pdf(temp_object)
        if content = to_pdf(temp_object.data)
          [
            content,
            {
              name:      [ temp_object.basename, 'pdf' ].join('.'),
              mime_type: "application/pdf"
            }
          ]
        else
          raise Heathen::NotConverted.new({
            temp_object:    temp_object,
            action:         'html_to_pdf',
            original_error: nil
          })
        end
      end

      private

        def to_pdf(source)
          PDFKit.new(source).to_pdf
        end
    end
  end
end

