class Spree::Calculator::Shipping::KoreanSurfaceMail <  Spree::ShippingCalculator
  def self.description
    "선편요금"
  end

  def self.register
    super
  end
end
