Spree::Order.class_eval do
  def display_presentation_gwansae
    @rate = @rate || Spree::CurrencyRate.find_by(:target_currency => 'KRW')
    in_won = @rate.convert_to_won(gwansae).to_f
    Spree::Money.new(in_won, {currency: "KRW"}).to_html
  end

  def display_presentation_bugasae
    @rate = @rate || Spree::CurrencyRate.find_by(:target_currency => 'KRW')
    in_won = @rate.convert_to_won(bugasae).to_f
    Spree::Money.new(in_won, {currency: "KRW"}).to_html
  end

  def display_presentation_hyeonjisobisae
    @rate = @rate || Spree::CurrencyRate.find_by(:target_currency => 'KRW')
    in_won = @rate.convert_to_won(included_tax_total).to_f
    Spree::Money.new(in_won, {currency: "KRW"}).to_html
  end
end
