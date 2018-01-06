class ConfigModel < WatirModel
  def self.create(hash = {})
    file = factory_file(self)
    env = ENV[self.to_s[/[^:]*$/].underscore.upcase]
    data = data_from_yaml(file, env) || {}
    new(data.merge hash)
  end

  def default_value(key, block)
    ENV[key.to_s.upcase] || instance_exec(&block)
  end
end
