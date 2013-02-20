module Heathen
  module Encoders
    class Url < Base

      class << self
        def encodes?(job)
          !job.meta[:url].empty?
        end
      end

      def encode(temp_object, format, args = { })

        if format != :pdf || temp_object.meta[:url].empty?
          throw :unable_to_handle
        end

        uri = URI.parse(temp_object.meta.fetch(:url))
        abs = absolutify(temp_object.data, uri)

        if content = PDFKit.new(abs).to_pdf
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
    end
  end
end

