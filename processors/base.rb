module Heathen
  module Processors
    class Base

      attr_reader :app

      def initialize(app)
        @app = app
      end
    end
  end
end

