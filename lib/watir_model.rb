require 'json'

class WatirModel
  class << self

    attr_writer :keys, :defaults, :data_types

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

    # define a key and an optional block that provides a default value for the key
    def key(symbol, data_type: nil, &block)
      keys << symbol unless @keys.include? symbol
      attr_accessor symbol
      data_types[symbol] = data_type if data_type
      defaults[symbol] = block if block
    end

    def convert_type(key, value)
      data_type = data_types[key]
      return value if data_type.nil?
      return value if data_type.is_a?(Class) && value.is_a?(data_type)
      value = case
              when data_type == String
                value.to_s
              when data_type == Time
                Time.parse value
              when data_type == DateTime
                DateTime.parse value
              when data_type == Integer
                value.to_i
              when data_type == Float
                value.to_f
              when data_type == :boolean
                return value if value.is_a?(TrueClass) || value.is_a?(FalseClass)
                value = eval(value)
                return value if value.is_a?(TrueClass) || value.is_a?(FalseClass)
                raise StandardError, "Unable to convert #{value} to TrueClass or FalseClass"
              when data_type == Symbol
                value.to_sym
              when data_type == Hash
                JSON.parse value
              when data_type == Array
                JSON.parse value
              else
                data_type.new(value)
              end
      return value if value.is_a?(data_type)
      raise StandardError, "Unable to convert #{value} to #{data_type}"
    end

    def convert(hash, *args)
      filtered = hash.reject { |k| !keys.include?(k) }
      model = new(filtered)
      args.each do |key|
        model.instance_eval do
          define_singleton_method(key) { hash[key] }
        end
      end
      model
    end
  end

  def initialize(hash={})
    update(hash)

    (self.class.defaults.keys - hash.keys).each do |key|
      block = self.class.defaults[key]
      value = default_value(key, block)
      value = self.class.convert_type(key, value)
      instance_variable_set("@#{key}", value)
    end
  end

  def update(hash)
    hash ||= {}

    unknown = hash.keys - keys
    if unknown.count > 0
      raise ArgumentError, "unknown keyword#{'s' if unknown.count > 1}: #{unknown.join ', '}"
    end
    hash.each do |key, val|
      instance_variable_set "@#{key}", self.class.convert_type(key, val)
    end
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
