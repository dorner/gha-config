module GhaConfig
  class Config
    attr_accessor :defaults
    attr_accessor :env
    attr_accessor :parsed_config
    attr_accessor :options
    attr_accessor :variables

    def initialize
      @env = {}
      @defaults = []
      @parsed_config = {}
      @options = {}
      @variables = {}
    end
  end
end
