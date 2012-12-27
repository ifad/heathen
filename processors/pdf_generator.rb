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
          return [ content, meta(temp_object) ]
        else
          raise Heathen::NotConverted.new({
            temp_object:    temp_object,
            action:         'html_to_pdf',
            original_error: nil
          })
        end
      end

      def url_to_pdf(temp_object)

        uri = URI.parse(temp_object.meta.fetch(:url))
        abs = absolutify(temp_object.data, uri)

        if content = to_pdf(abs)
          return [ content, meta(temp_object) ]
        else
          raise Heathen::NotConverted.new({
            temp_object:    temp_object,
            action:         'url_to_pdf',
            original_error: nil
          })
        end
      end

      private

        def meta(temp_object)
          {
            name:      [ temp_object.basename, 'pdf' ].join('.'),
            format:    :pdf,
            mime_type: "application/pdf"
          }
        end

        def absolutify(source, uri)

          string = source.dup
          pos    = 0

          while data = string.match(/(?:href|src)=['"](.+?)['"]/, pos)

            app.converter.log.info("data: #{data.inspect}")

            rel = URI.parse(data[1]) rescue nil
            pos = data.end(1)

            if rel && rel.host.nil?
              string[data.begin(1) ... pos] = (uri + rel).to_s
            end
          end

          string
        end

        def to_pdf(source)
          PDFKit.new(source).to_pdf
        end
    end
  end
end

