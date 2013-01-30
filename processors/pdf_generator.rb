module Heathen
  module Processors
    class HtmlConverter < Base

      MIME_TYPES = [ 'text/html' ]

      # return a [ content, meta ] pair, as expcted
      # by dragonfly
      def html_to_pdf(temp_object, args = { } )
        if content = to_pdf(temp_object.data)
          [ content, meta(temp_object, :pdf, 'application/pdf') ]
        else
          raise Heathen::NotConverted.new({
               temp_object: temp_object,
                    action: 'html_to_pdf',
            original_error: nil
          })
        end
      end

      def url_to_pdf(temp_object, args = { } )

        uri = URI.parse(temp_object.meta.fetch(:url))
        abs = absolutify(temp_object.data, uri)

        if content = to_pdf(abs)
          [ content, meta(temp_object, :pdf, 'application/pdf') ]
        else
          raise Heathen::NotConverted.new({
               temp_object: temp_object,
                    action: 'url_to_pdf',
            original_error: nil
          })
        end
      end

      private

        def absolutify(source, uri)

          string = source.dup
          pos    = 0

          while data = string.match(/(?:href|src)=['"](.+?)['"]/, pos)

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

