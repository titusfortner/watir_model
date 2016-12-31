require 'pp'

class ConfigModel < WatirModel
  def initialize(hash=nil)
    hash ||= {}
    update(hash)

    (self.class.defaults.keys - hash.keys).each do |key|
      block = self.class.defaults[key]
      object = self.class.data_types[key]
      result = ENV[key.to_s.upcase] || instance_exec(&block)
      value = process_type(object, result)
      instance_variable_set("@#{key}", value)
    end
  end
end
