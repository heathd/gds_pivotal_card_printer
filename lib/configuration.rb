class Configuration
  def initialize(config_file_path)
    @config = YAML.load_file(config_file_path)
  end
  
  def self.load(path = nil)
    path ||= File.join(ENV['HOME'], ".pivotal.yml")
    Configuration.new(path)
  end
  
  def method_missing(method, *args, &block)
    @config[method.to_s]
  end
end