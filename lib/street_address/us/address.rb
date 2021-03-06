# frozen_string_literal: true

# Address part generation
class StreetAddress::US::Address
  attr_accessor(
    :number,
    :street,
    :street_type,
    :unit,
    :unit_prefix,
    :suffix,
    :prefix,
    :city,
    :state,
    :postal_code,
    :postal_code_ext,
    :street2,
    :street_type2,
    :suffix2,
    :prefix2,
    :redundant_street_type
  )

  def initialize(args)
    args.each do |attr, val|
      public_send("#{attr}=", val)
    end
  end

  def full_postal_code
    return nil unless self.postal_code

    self.postal_code_ext ? "#{postal_code}-#{postal_code_ext}" : self.postal_code
  end

  def state_fips
    return StreetAddress::US::FIPS_STATES[state]
  end

  def state_name
    return StreetAddress::US::STATE_NAMES[state]&.capitalize
  end

  def intersection?
    return !street2.nil?
  end

  def line1_without_unit
    parts = []
    parts << number
    parts << prefix if prefix
    parts << street if street
    parts << street_type if street_type && !redundant_street_type
    parts << suffix if suffix
    return parts.join(" ").strip
  end

  def line1(string = "")
    parts = []
    if intersection?
      parts << prefix if prefix
      parts << street
      parts << street_type if street_type
      parts << suffix if suffix
      parts << "and"
      parts << prefix2 if prefix2
      parts << street2
      parts << street_type2 if street_type2
      parts << suffix2 if suffix2
    else
      parts << number
      parts << prefix if prefix
      parts << street if street
      parts << street_type if street_type && !redundant_street_type
      parts << suffix if suffix
      parts << unit_prefix if unit_prefix
      # follow guidelines: http://pe.usps.gov/cpim/ftp/pubs/Pub28/pub28.pdf pg28
      parts << (unit_prefix ? unit : "\# #{unit}") if unit
    end
    return string + parts.join(" ").strip
  end

  def line2(string = "")
    parts = []
    parts << city  if city
    parts << state if state
    string += parts.join(", ")
    if postal_code
      string += " #{postal_code}"
      string += "-#{postal_code_ext}" if postal_code_ext
    end
    return string.strip
  end

  def to_s(format = :default)
    s = ""
    case format
    when :line1
      s += line1(s)
    when :line2
      s += line2(s)
    else
      s += [line1, line2].reject(&:empty?).join(", ")
    end
    return s
  end

  def to_h
    return self.instance_variables.each_with_object({}) do |var_name, hash|
      var_value = self.instance_variable_get(var_name)
      hash_name = var_name[1..-1].to_sym
      hash[hash_name] = var_value
    end
  end

  def ==(other)
    return to_s == other.to_s
  end
end
