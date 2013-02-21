module Heathen
  module Processors
    class Base

      attr_reader :app

      def initialize(app)
        @app = app
      end

      def executioner
        @executioner ||= Heathen::Executioner.new(app.converter.log)
      end
    end
  end
end

