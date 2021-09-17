module GhaConfig
  module Parser
    def self.parse(input_file)
      input = File.read(input_file)
      input.gsub!(/(^|\n)on:/, %(\n"on":))
      hash = YAML.safe_load(input)
      config = GhaConfig::Config.new
      config.defaults = hash.delete('_defaults_') || {}
      config.options = hash.delete('_options_') || {}
      config.variables = hash.delete('_variables_') || {}
      config.env = hash.delete('env') || {}

      hash['jobs'] = replace_defaults(config, hash['jobs'])
      config.parsed_config = hash
      config
    end

    def self.replace_defaults(config, hash)
      if hash.is_a?(Array)
        return hash.map { |v| self.replace_defaults(config, v)}.compact.flatten
      elsif hash.is_a?(Hash)
        return hash.map { |k, v| [k, self.replace_defaults(config, v)] }.to_h
      end
      return hash unless hash.is_a?(String) && hash =~ /_.*_/
      return hash unless config.defaults.key?(hash)
      val = config.defaults[hash]
      if val.is_a?(Array)
        val.map { |v| self.replace_defaults(config, v) }.flatten
      else
        self.replace_defaults(config, val)
      end

    end

  end
end
