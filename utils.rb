module Heathen
  module Utils
    def present?(val)
      !blank?(val)
    end

    def blank?(val)
      val.nil? || empty?(val)
    end

    def empty?(val)
      if val.respond_to?(:empty?)
        if val.respond_to?(:strip)
          return val.strip.empty?
        else
          return val.empty?
        end
      end
    end
  end
end
