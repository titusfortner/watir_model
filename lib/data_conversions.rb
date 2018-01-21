module DataConversions

  def convert_to_string(value)
    value.to_s
  end

  def convert_to_time(value)
    Object.const_get(__callee__.to_s.gsub('convert_to_', '').camelcase).parse value
  end

  alias_method :convert_to_date, :convert_to_time
  alias_method :convert_to_date_time, :convert_to_time

  def convert_to_integer(value)
    value.to_i
  end

  def convert_to_float(value)
    value.to_f
  end

  def convert_to_boolean(value)
    return value if value.is_a?(TrueClass) || value.is_a?(FalseClass)
    value = eval(value)
    value.is_a?(TrueClass) || value.is_a?(FalseClass) ? value : nil
  end

  def convert_to_symbol(value)
    value.to_sym
  end

  def convert_to_hash(value)
    value = parse_json(value)
    value.to_h if value.respond_to? :to_h
  end

  def convert_to_array(value)
    value = parse_json(value)
    value.is_a?(Array) ? value : Array(value)
  end

  def parse_json(value)
    value = JSON.parse value
  rescue JSON::ParserError
    value
  end

end