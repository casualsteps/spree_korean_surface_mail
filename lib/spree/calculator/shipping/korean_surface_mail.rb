class Spree::Calculator::KoreanSurfaceMail <  Spree::Calculator
  #The rates are calculated using two different price_brackets the upper limit
  #is set here and can be overridden by the admin
  preference :lower_price_bracket_limit, :integer, :default => 200000
  #Depending on the price bracket the maximum weight (kg) of a package is decided
  preference :lower_price_bracket_max_weight, :decimal, :default => 20.00
  preference :upper_price_bracket_max_weight, :decimal, :default => 30.00
  preference :lower_price_bracket_weight_table, :string, :default => "2:13300 4:17800 6:22300 8:26700 10:31300 12:35700 14:40200 16:44700 18:49200 20:53600"
#  preference :lower_price_bracket_price_table, :string, :default => '13300 17800 22300 26700 31300 35700 40200 44700 49200 53600'
  preference :upper_price_bracket_weight_table, :string, :default => '1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30'
  preference :upper_price_bracket_price_table, :string, :default => '27000 41500 51000 57000 63000 69000 75000 81000 87000 93000 99000 105000 111000 117000 123000 129000 135000 141000 147000 153000 159000 165000 171000 177000 183000 189000 195000 201000 207000 213000'

  def self.description
    "선편요금"
  end

  def self.register
    super
  end

  def available?(order)
    if is_in_lower_price_bracket?(order) and calculate_total_weight(order) < self.preferred_lower_price_bracket_max_weight
      true
    elsif is_in_upper_price_bracket?(order) and calculate_total_weight(order) <= self.preferred_upper_price_bracket_max_weight
      true
    else
      false
    end
  end

  def compute(order)
    shipping_rate = 0
    return 0 if !available?(order)
    if is_in_lower_price_bracket?(order)
      price_table = self.preferred_lower_price_bracket_weight_table.split
      shipping_rate = price_table.select{ |price_weight| return Integer(price_weight.split(':').last) if calculate_total_weight(order) < BigDecimal(price_weight.split(':').first) }
    end
    shipping_rate
  end

  private
    def calculate_total_weight(order)
      order.line_items.reduce(0) { |total_weight, item| total_weight+= item.variant.weight }
    end

    def is_in_upper_price_bracket?(order)
      if order.total >= self.preferred_lower_price_bracket_limit then return true else return false end
    end

    def is_in_lower_price_bracket?(order)
      if is_in_upper_price_bracket?(order) == false then return true else return false end
    end
end
