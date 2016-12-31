require 'pp'

class WatirModel
  class << self

    attr_writer :keys, :defaults

    def keys
      @keys ||= []
    end

    def defaults
      @defaults ||= {}
    end

    def inherited(subclass)
      subclass.keys = keys.dup
      subclass.defaults = defaults.dup
    end

    # define a key and an optional block that provides a default value for the key
    def key(symbol, &block)
      keys << symbol unless @keys.include? symbol
      attr_accessor symbol
      defaults[symbol] = block if block
    end
  end

  def initialize(hash={})
    update(hash)

    (self.class.defaults.keys - hash.keys).each do |key|
      block = self.class.defaults[key]
      value = default_value(key, block)
      instance_variable_set("@#{key}", value)
    end
  end

  def update(hash)
    hash ||= {}

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

  def to_hash(opt = nil)
    opt ||= keys
    opt.each_with_object({}) do |key, hash|
      value = send(key)
      next if value.nil?
      hash[key] = value
    end
  end

  private

  def default_value(key, block)
    instance_exec(&block)
  end
end
