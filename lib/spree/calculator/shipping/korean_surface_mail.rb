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

  # seonpyeonyogeum (선편요금) -> Sea shipment fees
  # gwansae (관세) -> Customs duty/tariff
  # bugasae (부가세) -> VAT/surtax
  # hyeonjisobisae (현지소비세) -> Local(US) sales tax 
  # teukbyeolsobisae (특별소비세) -> Special excise tax
  # gyoyuksae (교육세) -> Education tax
  # nongteuksae (농특세) -> ??
 
  def compute_order(order)
    hyeonjisobisae_total = calculate_hyeonjisobisae(order)
    hyeonjisobisae_total = @currency_rate.convert_to_usd(hyeonjisobisae_total).to_f

    if !isApplicable?(order)
      order.update_columns(
        gwansae: 0,
        bugasae: 0
        included_tax_total: hyeonjisobisae_total
      )
      order.reload
      return 0
    end

    @currency_rate = @currency_rate || Spree::CurrencyRate.find_by(:target_currency => 'KRW')

    gwansae_total = 0
    bugasae_total = 0

    order.line_items.each do |li|
      # all calculations are in KRW
      gwansae = calculate_gwansae(li)
      bugasae = calculate_bugasae(li)
      gwansae_total += gwansae
      bugasae_total += bugasae
    end

    bugasae_total += calculate_teukbyeolsobisae(order) + calculate_gyoyuksae_or_nongteuksae(order, "gyoyuksae") + calculate_gyoyuksae_or_nongteuksae(order, "nongteuksae")

    gwansae_total = @currency_rate.convert_to_usd(gwansae_total).to_f
    bugasae_total = @currency_rate.convert_to_usd(bugasae_total).to_f

    order.update_columns(
      gwansae: gwansae_total,
      bugasae: bugasae_total,
      included_tax_total: hyeonjisobisae_total
    )
    order.reload
    gwansae_total + bugasae_total + hyeonjisobisae_total
  end

  #Spree calculates taxes on line items so it is calculated once for each line
  #item.  To calculate this as a total for the order, return the total for
  #the order divided by the number of line_items
  def compute_line_item(line_item)
    compute_order(line_item.order) / line_item.order.line_items.size
  end

  private

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

    def get_gwansae_rate(item)
      case item.product.category
      when /jewel/, /watch/, /bags/
        0.08
      else # clothing and others
        0.13
      end
    end
    
    def get_teukbyeolsobisae_rate(item)
      case item.product.category
      when /jewel/, /watch/
        0.2
      else 
        0
      end
    end

    def get_gyoyuksae_rate(item)
      case item.product.category
      when /jewel/, /watch/
        0.3
      else 
        0
      end
    end

    def get_nongteuksae_rate(item)
      # 농특세 is 10% for only 모피의류(fur) items over 200만원, ignore it for now
      0
    end

    def get_bugasae_rate(item)
      # 부가세 is always 10% regardless of category, but if this
      # changes in the future, logic can be added here
      0.1
    end

    def get_hyeonjisobisae_rate(item)
      case item.product.merchant
      when "gap", "bananarepublic", "footlocker"
        0.0625
      else 
        0
      end
    end

    def calculate_taxable_price(item)
      seonpyeonyogeum = calculate_seonpyeonyogeum(item.order)
      item_price = @currency_rate.convert_to_won(item.quantity * item.price).to_f
      order_price = @currency_rate.convert_to_won(item.order.item_total).to_f
      seonpyeonyogeum_for_this_item = seonpyeonyogeum * (item_price / order_price)
      local_shipping_charge = @currency_rate.convert_to_won(item.product.local_shipping_total).to_f
      hyeonjisobisae = calculate_hyeonjisobisae(item)
      taxable_price = item_price + hyeonjisobisae + seonpyeonyogeum_for_this_item + local_shipping_charge
      taxable_price
    end

    def calculate_gwansae(item)
      taxable_price = calculate_taxable_price(item)
      gwansae_rate = get_gwansae_rate(item)
      gwansae = taxable_price * gwansae_rate
      round_up(gwansae)
    end  

    def calculate_bugasae(item)
      taxable_price = calculate_taxable_price(item)
      gwansae = calculate_gwansae(item)
      teukbyeolsobisae = calculate_teukbyeolsobisae(item)
      gyoyuksae = calculate_gyoyuksae_or_nongteuksae(item, "gyoyuksae")
      nongteuksae = calculate_gyoyuksae_or_nongteuksae(item, "nongteuksae")
      additional_taxes = teukbyeolsobisae + gyoyuksae + nongteuksae
      bugasae_rate = get_bugasae_rate(item)
      bugasae = (taxable_price + gwansae + additional_taxes) * bugasae_rate
      round_up(bugasae)
    end

    def calculate_hyeonjisobisae(lineitem_or_order)
      items = case lineitem_or_order
        when Spree::LineItem then [lineitem_or_order]
        when Spree::Order then lineitem_or_order.line_items
      end

      return nil if items.empty?

      hyeonjisobisae = 0
      items.each { |item|
        item_price = @currency_rate.convert_to_won(item.quantity * item.price).to_f
        local_shipping_charge = @currency_rate.convert_to_won(item.product.local_shipping_total).to_f
        hyeonjisobisae_rate = get_hyeonjisobisae_rate(item)
        hyeonjisobisae += (item_price + local_shipping_charge) * hyeonjisobisae_rate
      }

      hyeonjisobisae
    end

    def calculate_teukbyeolsobisae(lineitem_or_order)
      items = case lineitem_or_order
        when Spree::LineItem then [lineitem_or_order]
        when Spree::Order then lineitem_or_order.line_items
      end
    
      return nil if items.empty?
    
      teukbyeolsobisae = 0
      items.each { |item|
        taxable_price = calculate_taxable_price(item)
        next if taxable_price <= 2000000
        gwansae = calculate_gwansae(item)
        teukbyeolsobisae_rate = get_teukbyeolsobisae_rate(item)
        teukbyeolsobisae += (taxable_price - 2000000 + gwansae) * teukbyeolsobisae_rate
      }
    
      teukbyeolsobisae
    end
    
    def calculate_gyoyuksae_or_nongteuksae(lineitem_or_order, tax_type)
      items = case lineitem_or_order
        when Spree::LineItem then [lineitem_or_order]
        when Spree::Order then lineitem_or_order.line_items
      end
    
      return nil if items.empty?
    
      tax_amount = 0
      items.each { |item|
        taxable_price = calculate_taxable_price(item)
        next if taxable_price <= 2000000
        teukbyeolsobisae = calculate_teukbyeolsobisae(item)
        if tax_type == "gyoyuksae"
          tax_rate = get_gyoyuksae_rate(item)
        elsif tax_type == "nongteuksae"
          tax_rate = get_nongteuksae_rate(item)
        end
        tax_amount += teukbyeolsobisae * tax_rate
      }
    
      tax_amount
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
