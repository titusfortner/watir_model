require "model/version"
require 'pp'

class Model
  class << self

    attr_reader :keys, :defaults

    # define a key and an optional block that provides a default value for the key
    def key(symbol, &block)
      @keys ||= []
      @keys << symbol
      attr_accessor symbol
      @defaults ||= {}
      @defaults[symbol] = block if block
    end
  end

  def initialize(hash={})
    unknown = hash.keys - keys
    if unknown.count > 0
      raise ArgumentError, "unknown keyword#{'s' if unknown.count > 1}: #{unknown.join', '}"
    end
    hash.each_pair {|key, v| instance_variable_set "@#{key}", v}
    (self.class.defaults.keys - hash.keys).each do |key|
      block = self.class.defaults[key]
      instance_variable_set("@#{key}", instance_exec(&block))
    end
  end

  def keys
    self.class.keys
  end

end
