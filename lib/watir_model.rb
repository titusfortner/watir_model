require 'active_support/hash_with_indifferent_access'
require 'json'
require 'date'
require 'time'
require 'yml_reader'

class WatirModel
  class << self
    include YmlReader

    attr_writer :keys, :aliases, :data_types, :defaults, :apis

    def keys
      @keys ||= []
    end

    def aliases
      @aliases ||= {}
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

    def inherited(subclass)
      subclass.keys = keys.dup
      subclass.aliases = aliases.dup
      subclass.apis = apis.dup
      subclass.defaults = defaults.dup
      subclass.data_types = data_types.dup
    end

    def key(symbol, data_type: nil, aliases: [], api: nil, &block)
      keys << symbol unless @keys.include? symbol
      aliases.each { |alias_key| self.aliases[alias_key] = symbol }
      attr_accessor symbol
      apis[api] = symbol if api
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
              when data_type == Time, Date, DateTime
                data_type.parse value
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
                file = factory_file(data_type)
                data = data_from_yaml(file, value) || value
                data_type.new(data)
              end
      return value if value.is_a?(data_type)
      raise StandardError, "Unable to convert #{value} to #{data_type}"
    end

    def convert(hash, *args)
      hash.deep_symbolize_keys!
      filtered = hash.select { |k| (keys + aliases.keys + apis.keys).include?(k) }
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

    def method_missing(method, *args, &block)
      file = factory_file(self)
      return super unless file
      data = data_from_yaml(file, method)
      raise ArgumentError, "Factory '#{method}' does not exist in '#{file}'" if data.nil?
      new(data)
    end

    def factory_file(type)
      Dir.glob("#{WatirModel.yml_directory}/#{type.to_s[/[^:]*$/].downcase}.yml").first
    end

    def data_from_yaml(file, value)
      return nil if file.nil? || !(value.is_a?(Symbol) || value.is_a?(String))
      YAML.load_file(file)[value.to_sym]
    end
  end

  def initialize(hash={})
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

    (hash.keys & aliases.keys).each do |alias_key|
      hash[aliases[alias_key]] = hash.delete(alias_key)
    end

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

  def aliases
    self.class.aliases
  end

  def apis
    self.class.apis
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
      value = value.to_hash if value.is_a? WatirModel
      hash[key] = value
    end
  end

  def to_api
    hash = to_hash
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
