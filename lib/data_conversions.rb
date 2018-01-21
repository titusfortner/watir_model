module DataConversions

  def convert_string(value)
    value.to_s
  end

  def convert_time(value)
    Object.const_get(__callee__.to_s.gsub('convert_', '').camelcase).parse value
  end

  alias_method :convert_date, :convert_time
  alias_method :convert_date_time, :convert_time

  def convert_integer(value)
    value.to_i
  end

  def convert_float(value)
    value.to_f
  end

  def convert_boolean(value)
    return value if value.is_a?(TrueClass) || value.is_a?(FalseClass)
    value = eval(value)
    value.is_a?(TrueClass) || value.is_a?(FalseClass) ? value : nil
  end

  def convert_symbol(value)
    value.to_sym
  end

  def convert_hash(value)
    value = parse_json(value)
    value.to_h if value.respond_to? :to_h
  end

  def convert_array(value)
    value = parse_json(value)
    value.is_a?(Array) ? value : Array(value)
  end

  def parse_json(value)
    value = JSON.parse value
  rescue JSON::ParserError
    value
  end

end