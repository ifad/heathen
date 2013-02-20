module Heathen

  ACTIONS = %w{ pdf ocr }

  LANGUAGES = %w{ eng spa }

  class NotConverted < RuntimeError
    attr_reader :temp_object, :action, :original_error
    def initialize(args = { })
      @temp_object, @action, @original_error = args.values_at(:temp_object, :action, :original_error)
    end
  end
end
