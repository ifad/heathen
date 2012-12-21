module Heathen

  PROCESSORS = %w{
    office_to_pdf
  }

  class NotConverted < RuntimeError
    attr_reader :temp_object, :action, :original_error
    def initialize(args = { })
      @temp_object, @action, @original_error = args.values_at(:temp_object, :action, :original_error)
    end
  end
end