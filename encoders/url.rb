module Heathen
  module Encoders
    class Url < Base

      include Concerns::Wkhtmltopdf

      include Heathen::Utils
      extend Heathen::Utils

      class << self
        def encodes?(job)
          present?(job.meta[:url])
        end
      end

      def encode(temp_object, format, args = { })

        if format != :pdf || blank?(temp_object.meta[:url])
          throw :unable_to_handle
        end

        uri = URI.parse(temp_object.meta.fetch(:url))

        if content = wkhtmltopdf(uri)
          [ content, meta(temp_object, :pdf, 'application/pdf') ]
        else
          raise Heathen::NotConverted.new({
               temp_object: temp_object,
                    action: 'url_to_pdf',
                   command: executioner.last_command,
            original_error: executioner.last_messages
          })
        end
      end

    end
  end
end

