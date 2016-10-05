require 'pp'

class WatirModel
  class << self

    attr_writer :keys, :data_types, :defaults

    def keys
      @keys ||= []
    end

    def data_types
      @data_types ||= {}
    end

    def defaults
      @defaults ||= {}
    end

    def inherited(subclass)
      subclass.keys = keys.dup
      subclass.defaults = defaults.dup
      subclass.data_types = data_types.dup
    end

    %w(string float integer symbol time).each do |type|
      define_method(type) do |symbol, &block|
        key(symbol, &block)
        data_types[symbol] = Object.const_get(type.capitalize)
      end
    end

    def boolean(symbol, &block)
      key(symbol, &block)
      data_types[symbol] = 'Boolean'
    end

    # define a key and an optional block that provides a default value for the key
    def key(symbol, &block)
      keys << symbol unless @keys.include? symbol
      attr_accessor symbol
      data_types[symbol] = 'Key'
      defaults[symbol] = block if block
    end
  end

  def initialize(hash=nil)
    hash ||= {}
    update(hash)

    (self.class.defaults.keys - hash.keys).each do |key|
      block = self.class.defaults[key]
      object = self.class.data_types[key]
      result = ENV[key.to_s.upcase] || instance_exec(&block)
      value = case
              when object == 'Key'
                result
              when object == Symbol
                result.to_sym
              when object == String
                result.to_s
              when object == Integer
                result.to_i
              when object == Float
                result.to_f
              when object == 'Boolean'
                result.is_a?(String) ? eval(result) : result
              else
                object.new result
              end
      instance_variable_set("@#{key}", value)
    end
  end

  def update(hash)
    unknown = hash.keys - keys
    if unknown.count > 0
      raise ArgumentError, "unknown keyword#{'s' if unknown.count > 1}: #{unknown.join ', '}"
    end
    hash.each { |key, v| instance_variable_set "@#{key}", v }
  end

  def keys
    self.class.keys
  end

  def [] key
    send key
  end

  def eql?(other)
    keys.all? { |k| send(k) == other[k] }
  end
  alias_method :==, :eql?

  def self.convert(hash)
    id = hash[:id]
    filtered = hash.delete_if { |k| !keys.include?(k) }
    new(filtered).tap { |m| m.id = id }
  end

  def to_hash(opt = nil)
    opt ||= keys
    opt.each_with_object({}) do |key, hash|
      value = send(key)
      hash[key] = process_value(value)
    end
  end
  alias_method :to_h, :to_hash

  def process_value(value)
    case value
    when WatirModel
      value.to_hash
    when Hash
      process_value(value)
    when Array
      value.map { |v| process_value(v) }
    else
      value
    end
  end

  def to_json(opt={})
    to_hash.to_json(opt)
  end

end
