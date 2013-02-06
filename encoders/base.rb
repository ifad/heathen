module Heathen
  module Encoders
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

        def raw_identify(temp_object, args='')
          `identify #{args} #{temp_object.path}`
        end

        def identify(temp_object)
          # example of details string:
          # myimage.png PNG 200x100 200x100+0+0 8-bit DirectClass 31.2kb
          format, width, height, depth = raw_identify(temp_object).scan(/([A-Z0-9]+) (\d+)x(\d+) .+ (\d+)-bit/)[0]
          {
            :format => format.downcase.to_sym,
            :width => width.to_i,
            :height => height.to_i,
            :depth => depth.to_i
          }
        end
    end
  end
end

