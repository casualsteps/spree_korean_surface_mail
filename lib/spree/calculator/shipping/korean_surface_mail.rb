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
    @taxable_prices = {}
    @currency_rate = @currency_rate || Spree::CurrencyRate.find_by(:target_currency => 'KRW')
    hyeonjisobisae_total = calculate_hyeonjisobisae(order)
    hyeonjisobisae_total = @currency_rate.convert_to_usd(hyeonjisobisae_total).to_f

    if !isApplicable?(order)
      order.update_columns(
        gwansae: 0,
        bugasae: 0,
        included_tax_total: hyeonjisobisae_total
      )
      order.reload
      return hyeonjisobisae_total
    end

    gwansae_total = 0

    order.line_items.each do |li|
      # all calculations are in KRW
      gwansae = calculate_gwansae(li)
      bugasae = calculate_bugasae(li)
      gwansae_total += (bugasae + gwansae)
    end
    gwansae_total += 5000
    other_taxes_total = calculate_teukbyeolsobisae(order) + calculate_gyoyuksae_or_nongteuksae(order, "gyoyuksae") + calculate_gyoyuksae_or_nongteuksae(order, "nongteuksae")

    gwansae_total = @currency_rate.convert_to_usd(gwansae_total).to_f
    other_taxes_total = @currency_rate.convert_to_usd(other_taxes_total).to_f

    order.update_columns(
      gwansae: gwansae_total,       # gwansae has both gwansae and bugasae
      bugasae: other_taxes_total,   # we use bugasae columns for other taxes
      included_tax_total: hyeonjisobisae_total
    )
    order.reload
    gwansae_total + other_taxes_total + hyeonjisobisae_total
  end

  def compute_product(product)
    @taxable_prices = {}
    @currency_rate = @currency_rate || Spree::CurrencyRate.find_by(:target_currency => 'KRW')
    hyeonjisobisae_total = calculate_hyeonjisobisae(product)
    hyeonjisobisae_total = @currency_rate.convert_to_usd(hyeonjisobisae_total).to_f
    if !isApplicable?(product)
      return hyeonjisobisae_total
    end

    gwansae_total = 0
    gwansae = calculate_gwansae(product)
    bugasae = calculate_bugasae(product)
    gwansae_total += (bugasae + gwansae)
    gwansae_total += 5000
    gwansae_total = @currency_rate.convert_to_usd(gwansae_total).to_f

    other_taxes_total = calculate_teukbyeolsobisae(product) + calculate_gyoyuksae_or_nongteuksae(product, "gyoyuksae") + calculate_gyoyuksae_or_nongteuksae(product, "nongteuksae")
    other_taxes_total = @currency_rate.convert_to_usd(other_taxes_total).to_f

    gwansae_total + other_taxes_total + hyeonjisobisae_total
  end

  #Spree calculates taxes on line items so it is calculated once for each line
  #item.  To calculate this as a total for the order, return the total for
  #the order divided by the number of line_items
  def compute_line_item(line_item)
    compute_order(line_item.order) / line_item.order.line_items.size
  end

  private

    def calculate_seonpyeonyogeum(lineitem_or_product)
      item = lineitem_or_product.try(:order) ? lineitem_or_product.order : lineitem_or_product
      shipping_rate = 0
      if is_in_lower_price_bracket?(item)
        price_table = self.preferred_lower_price_bracket_weight_table.split
        shipping_rate = price_table.select{ |price_weight| return Integer(price_weight.split(':').last) if calculate_total_weight(item) < BigDecimal(price_weight.split(':').first) }
      elsif is_in_upper_price_bracket?(item)
        price_table = self.preferred_upper_price_bracket_weight_table.split
        shipping_rate = price_table.select{ |price_weight| return Integer(price_weight.split(':').last) if calculate_total_weight(item) < BigDecimal(price_weight.split(':').first) }
      end
      shipping_rate
    end

    def isApplicable?(order_or_product)
      if is_in_lower_price_bracket?(order_or_product) and calculate_total_weight(order_or_product).to_f < self.preferred_lower_price_bracket_max_weight
        true
      elsif is_in_upper_price_bracket?(order_or_product) and calculate_total_weight(order_or_product).to_f <= self.preferred_upper_price_bracket_max_weight
        true
      else
        false
      end
    end

    def round_up(amount)
      BigDecimal.new(amount.to_s).round()
    end

    def get_gwansae_rate(item)
      category = case item
        when Spree::LineItem  then item.product.try(:category)
        when Spree::Product   then item.try(:category)
      end
      return 0 unless category
      case category
      when /jewel/, /watch/, /bags/
        0.08
      else # clothing and others
        0.13
      end
    end

    def get_teukbyeolsobisae_rate(item)
      category = case item
        when Spree::LineItem  then item.product.try(:category)
        when Spree::Product   then item.try(:category)
      end
      return 0 unless category
      case category
      when /jewel/, /watch/
        0.2
      else 
        0
      end
    end

    def get_gyoyuksae_rate(item)
      category = case item
        when Spree::LineItem  then item.product.try(:category)
        when Spree::Product   then item.try(:category)
      end
      return 0 unless category
      case category
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
      # Return 0 since we have moved to new shipping company in NJ
      # which has no sales tax.
      0
    end

    def calculate_taxable_price(lineitem_or_product)
      return @taxable_prices[lineitem_or_product.id] if @taxable_prices[lineitem_or_product.id].present?
      seonpyeonyogeum = calculate_seonpyeonyogeum(lineitem_or_product)
      item_price = @currency_rate.convert_to_won(quantity(lineitem_or_product) * total(lineitem_or_product)).to_f
      order_price = @currency_rate.convert_to_won(total(lineitem_or_product)).to_f
      seonpyeonyogeum_for_this_item = seonpyeonyogeum * (item_price / order_price)
      local_shipping_charge = @currency_rate.convert_to_won(local_shipping_total(lineitem_or_product)).to_f
      hyeonjisobisae = calculate_hyeonjisobisae(lineitem_or_product)
      taxable_price = item_price + hyeonjisobisae + seonpyeonyogeum_for_this_item + local_shipping_charge
      @taxable_prices[lineitem_or_product.id] = taxable_price
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

    def calculate_hyeonjisobisae(lineitem_or_order_or_product)
      items = case lineitem_or_order_or_product
        when Spree::LineItem, Spree::Product then [lineitem_or_order_or_product]
        when Spree::Order then lineitem_or_order_or_product.line_items
      end

      hyeonjisobisae = 0
      items.each { |item|
        next unless item
        item_price = @currency_rate.convert_to_won(quantity(item) * item.price).to_f
        local_shipping_charge = @currency_rate.convert_to_won(local_shipping_total(item)).to_f
        hyeonjisobisae_rate = get_hyeonjisobisae_rate(item)
        hyeonjisobisae += (item_price + local_shipping_charge) * hyeonjisobisae_rate
      }
      hyeonjisobisae
    end

    def calculate_teukbyeolsobisae(lineitem_or_order_or_product)
      items = case lineitem_or_order_or_product
        when Spree::LineItem, Spree::Product then [lineitem_or_order_or_product]
        when Spree::Order then lineitem_or_order_or_product.line_items
      end

      teukbyeolsobisae = 0
      items.each { |item|
        next unless item
        taxable_price = calculate_taxable_price(item)
        next if taxable_price <= 2000000
        gwansae = calculate_gwansae(item)
        teukbyeolsobisae_rate = get_teukbyeolsobisae_rate(item)
        teukbyeolsobisae += (taxable_price - 2000000 + gwansae) * teukbyeolsobisae_rate
      }
      teukbyeolsobisae
    end

    def calculate_gyoyuksae_or_nongteuksae(lineitem_or_order_or_product, tax_type)
      items = case lineitem_or_order_or_product
        when Spree::LineItem, Spree::Product then [lineitem_or_order_or_product]
        when Spree::Order then lineitem_or_order_or_product.line_items
      end

      tax_amount = 0
      items.each { |item|
        next unless item
        taxable_price = calculate_taxable_price(item)
        next if taxable_price <= 2000000
        teukbyeolsobisae = calculate_teukbyeolsobisae(item)
        tax_rate = case tax_type
          when "gyoyuksae" then get_gyoyuksae_rate(item)
          when "nongteuksae" then get_nongteuksae_rate(item)
        end
        tax_amount += teukbyeolsobisae * tax_rate
      }

      tax_amount
    end

    def calculate_total_weight(order_or_product)
      #Currently we get all weights in hundreths of a pound calculate this
      #value in kg might be worth using https://github.com/joshwlewis/unitwise
      #for this
      total_weight = case order_or_product
        when Spree::Product then calculate_weight(order_or_product.master)
        when Spree::Order then order_or_product.line_items.reduce(0) { |total, item| total + (calculate_weight(item.variant)  * item.quantity) }
      end
      total_weight
    end

    def calculate_weight(variant)
      @shipping_calculator ||= Spree::Calculator::Shipping::Ohmyzip.first
      weight = variant.weight > 0.0 ? variant.weight : @shipping_calculator.preferred_default_weight
      (weight * 4.53592)/1000
    end

    def is_in_upper_price_bracket?(order_or_product)
      total(order_or_product).to_f >= self.preferred_lower_price_bracket_limit
    end

    def is_under_lower_price_bracket_minimum?(order_or_product)
      total(order_or_product).to_f > self.preferred_lower_price_bracket_minimum
    end

    def is_in_lower_price_bracket?(order_or_product)
      is_in_upper_price_bracket?(order_or_product) == false and is_under_lower_price_bracket_minimum?(order_or_product) == true
    end

    def quantity(lineitem_or_product)
      lineitem_or_product.try(:quantity) ? lineitem_or_product.quantity : 1
    end

    def local_shipping_total(lineitem_or_product)
      ret = case lineitem_or_product
      when Spree::LineItem  then lineitem_or_product.product.try(:local_shipping_total)
      when Spree::Product   then lineitem_or_product.local_shipping_total
      end
      return 0 unless ret
      ret
    end

    def total(lineitem_or_order_or_product)
      total = case lineitem_or_order_or_product
        when Spree::Product, Spree::LineItem  then lineitem_or_order_or_product.price
        when Spree::Order                     then lineitem_or_order_or_product.item_total
      end
      total
    end
end
