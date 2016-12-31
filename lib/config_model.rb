require 'pp'

class ConfigModel < WatirModel
  def default_value(key, block)
    ENV[key.to_s.upcase] || instance_exec(&block)
  end
end
