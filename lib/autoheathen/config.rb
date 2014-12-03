module AutoHeathen
  module Config
    def load_config defaults={}, config_file=nil, overwrites={}
      cfg = symbolize_keys(defaults)
      if config_file && File.exist?(config_file)
        cfg.merge! symbolize_keys(YAML::load_file config_file)
      end
      cfg.merge! symbolize_keys(overwrites)  # non-file opts have precedence
      return cfg
    end

    def symbolize_keys(hash)
      (hash||{}).inject({}){|result, (key, value)|
        new_key = key.is_a?(String) ? key.to_sym : key
        new_value = value.is_a?(Hash) ? symbolize_keys(value) : value
        result[new_key] = new_value
        result
      }
    end
  end
end
