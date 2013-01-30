module Heathen
  module Processors
    class Base

      MIME_TYPES = %{}

      attr_reader :app

      class << self
        def valid_mime_type?(mime_type)
          return self::MIME_TYPES.include?(mime_type)
        end
      end

      def initialize(app)
        @app = app
      end

      protected

        def meta(temp_object, format, mime, args = { } )
          args.merge({
                 name: [ temp_object.basename, 'pdf' ].join('.'),
               format: format,
            mime_type: mime
          })
        end
    end
  end
end

