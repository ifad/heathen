module Heathen
  module Encoders
    class Base

      MIME_TYPES = %{ }

      attr_reader :app

      class << self

        def inherited(sub)
          (@subclasses ||= [ ]) << sub
        end

        def valid_mime_type?(mime_type)
          return self::MIME_TYPES.include?(mime_type)
        end

        def can_encode?(job)
          @subclasses.any? { |sub| sub.encodes?(job) }
        end

        # default implementation
        def encodes?(job)
          valid_mime_type?(job.mime_type)
        end
      end

      def initialize(app)
        @app = app
      end

      def executioner
        @executioner ||= Heathen::Executioner.new(app.converter.log)
      end

      protected

        def meta(temp_object, format, mime, args = { })
          args.merge({
                 name: [ temp_object.basename, 'pdf' ].join('.'),
               format: format,
            mime_type: mime
          })
        end

    end

    def self.can_encode?(job)
      Base.can_encode?(job)
    end
  end
end

