module Heathen

  ACTIONS = %w{ pdf ocr doc }

  LANGUAGES = %w{ eng spa }

  class NotConverted < RuntimeError
    attr_reader :temp_object, :action, :original_error, :command
    def initialize(args = { })
      @temp_object, @action, @original_error, @command =
        args.values_at(:temp_object, :action, :original_error, :command)
    end
  end
end
