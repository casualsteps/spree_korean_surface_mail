class Spree::Calculator::KoreanSurfaceMail <  Spree::Calculator
  #The rates are calculated using two different price_brackets the upper limit
  #is set here and can be overridden by the admin
  preference :limit_currency, :string, :default => 'USD'
  preference :lower_price_bracket_minimum, :integer, :default => 200
  preference :lower_price_bracket_limit, :integer, :default => 200
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

  def rate
    self.calculable
  end

  def compute_shipment(shipment)
    0
  end

  def compute_shipping_rate(shipping_rate)
    0
  end

  def compute_order(order)
    if !isApplicable?(order)
      order.update_columns(
        gwansae: 0,
        bugasae: 0
      )
      order.reload
      return 0
    end

    @currency_rate = @currency_rate || Spree::CurrencyRate.find_by(:target_currency => 'KRW')
    # vinay
    order.line_items.each { |item|
      #binding.pry
      puts item.price
    }
    seonpyeonyogeum = calculate_seonpyeonyogeum(order)
    gwansae_rate = get_gwansae_rate(order)
    bugasae_rate = get_bugasae_rate(order)
    order_total = order.presentation_item_total

    taxable_price = seonpyeonyogeum + order_total
    gwansae = round_up(taxable_price * gwansae_rate)
    bugasae = (taxable_price + gwansae) * bugasae_rate
    bugasae = round_up(bugasae)
    gwansae = @currency_rate.convert_to_usd(gwansae).to_f
    bugasae = @currency_rate.convert_to_usd(bugasae).to_f

    order.update_columns(
      gwansae: gwansae,
      bugasae: bugasae
    )
    order.reload
    gwansae + bugasae
  end

  #Spree calculates taxes on line items so it is calculated once for each line
  #item.  To calculate this as a total for the order, return the total for
  #the order divided by the number of line_items
  def compute_line_item(line_item)
    compute_order(line_item.order) / line_item.order.line_items.size
  end

  def calculate_seonpyeonyogeum(order)
    shipping_rate = 0
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

    def isApplicable?(order)
      if is_in_lower_price_bracket?(order) and calculate_total_weight(order) < self.preferred_lower_price_bracket_max_weight
        true
      elsif is_in_upper_price_bracket?(order) and calculate_total_weight(order) <= self.preferred_upper_price_bracket_max_weight
        true
      else
        false
      end
    end

    def round_up(amount)
      BigDecimal.new(amount.to_s).round()
    end

    def get_gwansae_rate(order)
      # For now, 관세 is simply 13% for clothing/shoes
      # TODO LATER: Each item in the order will need to have its
      # 관세 calculated separately depending on its category
      0.13
    end

    def get_bugasae_rate(order)
      # 부가세 is always 10% regardless of category, but if this
      # changes in the future, logic can be added here
      0.1
    end

    def calculate_total_weight(order)
      #Currently we get all weights in hundreths of a pound calculate this
      #value in kg might be worth using https://github.com/joshwlewis/unitwise
      #for this
      order.line_items.reduce(0) { |total_weight, item| total_weight+= ((item.variant.weight * 4.53592)/1000) * item.quantity }
    end

    def calculate_total_price(order)
      order.item_total + order.mock_shipment_total
    end

    def is_in_upper_price_bracket?(order)
      order.item_total >= self.preferred_lower_price_bracket_limit
    end

    def is_under_lower_price_bracket_minimum?(order)
      order.item_total > self.preferred_lower_price_bracket_minimum
    end

    def is_in_lower_price_bracket?(order)
      is_in_upper_price_bracket?(order) == false and is_under_lower_price_bracket_minimum?(order) == true
    end

end
