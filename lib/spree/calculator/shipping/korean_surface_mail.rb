class Spree::Calculator::KoreanSurfaceMail <  Spree::Calculator
  #The rates are calculated using two different price_brackets the upper limit
  #is set here and can be overridden by the admin
  preference :lower_price_bracket_minimum, :integer, :default => 0
  preference :lower_price_bracket_limit, :integer, :default => 200000
  #Depending on the price bracket the maximum weight (kg) of a package is decided
  preference :lower_price_bracket_max_weight, :decimal, :default => 20.00
  preference :upper_price_bracket_max_weight, :decimal, :default => 30.00
  preference :lower_price_bracket_weight_table, :string, :default => "2:13300 4:17800 6:22300 8:26700 10:31300 12:35700 14:40200 16:44700 18:49200 20:53600"
  preference :upper_price_bracket_weight_table, :string, :default => '1:27000 2:41500 3:51000 4:57000 5:63000 6:69000 7:75000 8:81000 9:87000 10:93000 11:99000 12:105000 13:111000 14:117000 15:123000 16:129000 17:135000 18:141000 19:147000 20:153000 21:159000 22:165000 23:171000 24:177000 25:183000 26:189000 27:195000 28:201000 29:207000 30:213000'

  def self.description
    "Korean customs tax (관세 + 부가세)"
  end

  def self.register
    super
  end

  def available?(order)
    # TODO: need some way to calculate order total in USD for the below logic:
    # if order.item_total.to_usd < 200
    #   false
    if is_in_lower_price_bracket?(order) and calculate_total_weight(order) < self.preferred_lower_price_bracket_max_weight
      true
    elsif is_in_upper_price_bracket?(order) and calculate_total_weight(order) <= self.preferred_upper_price_bracket_max_weight
      true
    else
      false
    end
  end

  def rate
    self.calculable
  end

  def compute_order(order)
    return 0 if !available?(order)
    seonpyeonyogeum = calculate_seonpyeonyogeum(order)
    gwansae_rate = get_gwansae(order)
    bugasae_rate = get_bugasae(order)
    order_total = order.item_total

    taxable_price = seonpyeonyogeum + order_total
    gwansae = taxable_price * gwansae_rate
    bugasae = (taxable_price + gwansae) * bugasae_rate
    return (gwansae + bugasae).to_s("F")
  end

  #Spree calculates taxes on line items so it is calculated once for each line
  #item.  To calculate this as a total for the order, return the total for
  #the order divided by the number of line_items

  def compute_line_item(line_item)
    tax = (rate.amount * compute_order(line_item.order)) / line_item.order.line_items.size
    tax
  end

  def calculate_seonpyeonyogeum(order)
    shipping_rate = 0
    return 0 if !available?(order)
    if is_in_lower_price_bracket?(order)
      price_table = self.preferred_lower_price_bracket_weight_table.split
      shipping_rate = price_table.select{ |price_weight| return Integer(price_weight.split(':').last) if calculate_total_weight(order) < BigDecimal(price_weight.split(':').first) }
    elsif is_in_upper_price_bracket?(order)
      price_table = self.preferred_upper_price_bracket_weight_table.split
      shipping_rate = price_table.select{ |price_weight| return Integer(price_weight.split(':').last) if calculate_total_weight(order) < BigDecimal(price_weight.split(':').first) }
    end
    shipping_rate
  end

  private
    def get_gwansae(order)
      # For now, 관세 is simply 13% for clothing/shoes
      # TODO LATER: Have this check each item in the order for
      # its tax category, and return the corrct rate for the
      # order. Will need to double-check logic here.
      0.13
    end

    def get_bugasae(order)
      # 부가세 is always 10% regardless of category, but if this
      # changes in the future, logic can be added here
      0.1
    end

    def calculate_total_weight(order)
      #Currently we get all weights in hundreths of a pound calculate this
      #value in kg might be worth using https://github.com/joshwlewis/unitwise
      #for this
      order.line_items.reduce(0) { |total_weight, item| total_weight+= (item.variant.weight * 4.53592)/1000 }
    end

    def is_in_upper_price_bracket?(order)
      if order.item_total >= self.preferred_lower_price_bracket_limit then return true else return false end
    end

    def is_under_lower_price_bracket_minimum?(order)
      if order.item_total > self.preferred_lower_price_bracket_minimum then return true else return false end
    end

    def is_in_lower_price_bracket?(order)
      if is_in_upper_price_bracket?(order) == false and is_under_lower_price_bracket_minimum?(order) == true then return true else return false end
    end
end
