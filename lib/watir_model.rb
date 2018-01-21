require 'active_support/hash_with_indifferent_access'
require 'active_support/core_ext/string'

require 'json'
require 'date'
require 'time'
require 'faker'
require 'yml_reader'
require 'data_conversions'

class WatirModel
  class << self
    include YmlReader
    include DataConversions

    attr_writer :keys, :data_types, :defaults, :apis

    def keys
      @keys ||= []
    end

    def data_types
      @data_types ||= {}
    end

    def apis
      @apis ||= {}
    end

    def defaults
      @defaults ||= {}
    end

    def valid_keys
      keys + apis.keys
    end

    def inherited(subclass)
      subclass.keys = keys.dup
      subclass.apis = apis.dup
      subclass.defaults = defaults.dup
      subclass.data_types = data_types.dup
    end

    def key(symbol, data_type: nil, api: nil, &block)
      keys << symbol unless @keys.include? symbol
      attr_accessor symbol
      apis[api] = symbol if api
      data_types[symbol] = data_type if data_type
      defaults[symbol] = block if block
    end

    def convert_type(key, value)
      data_type = data_types[key]
      return value if data_type.nil?
      return value if data_type.is_a?(Class) && value.is_a?(data_type)
      method = "convert_#{data_type.to_s.underscore}"
      value = if respond_to? method
                send(method, value)
              else
                file = factory_file(data_type)
                data = data_from_yaml(file, value) || value
                data_type.new(data)
              end
      return value unless value.nil?
      raise StandardError, "Unable to convert #{value} to #{data_type}"
    end

    def convert(hash, *args)
      hash.deep_symbolize_keys!
      filtered = hash.select { |k| valid_keys.include?(k) }
      unless (defaults.keys - default_value_keys(filtered)).empty?
        raise StandardError, "Can not convert Hash to Model when keys with default values are missing"
      end
      model = new(filtered)
      args.each do |key|
        model.instance_eval do
          define_singleton_method(key) { hash[key] }
        end
      end
      model
    end

    def default_directory
      'config/data'
    end

    def default_value_keys(hash)
      hash.keys.map do |key|
        keys.include?(key) ? key : apis[key]
      end
    end

    def method_missing(method, *args, &block)
      file = factory_file(self)
      return super unless file
      data = data_from_yaml(file, method)
      raise ArgumentError, "Factory '#{method}' does not exist in '#{file}'" if data.nil?
      new(data)
    end

    def factory_file(type)
      Dir.glob("#{WatirModel.yml_directory}/#{type.to_s[/[^:]*$/].underscore}.yml").first
    end

    def data_from_yaml(file, value)
      return nil if file.nil? || !(value.is_a?(Symbol) || value.is_a?(String))
      YAML.load_file(file)[value.to_sym]
    end
  end

  def initialize(hash = {})
    hash.deep_symbolize_keys!
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

    (hash.keys & apis.keys).each do |api_key|
      hash[apis[api_key]] = hash.delete(api_key)
    end

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

  def apis
    self.class.apis
  end

  def valid_keys
    self.class.valid_keys
  end

  def [] key
    send key
  end

  def eql?(other)
    keys.all? { |k| send(k) == other[k] }
  end
  alias_method :==, :eql?

  def to_hash(opt = nil)
    warn "#to_hash is deprecated, use #to_h instead"
    to_h opt
  end

  def to_h(opt = nil)
    opt ||= keys
    opt.each_with_object({}) do |key, hash|
      value = send(key)
      next if value.nil?
      value = value.to_h if value.is_a? WatirModel
      hash[key] = value
    end
  end

  def to_json(*)
    to_h.to_json
  end

  def to_api
    hash = to_h
    apis.each do |key, value|
      hash[key] = hash.delete(value)
    end
    hash.to_json
  end

  private

  def default_value(key, block)
    instance_exec(&block)
  end
end
