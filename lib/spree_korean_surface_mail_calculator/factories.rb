FactoryGirl.define do
  # Define your Spree extensions Factories within this file to enable applications, and other extensions to use and override them.
  #
  # Example adding this to your spec_helper will load these Factories for use:
  # require 'spree_korean_surface_mail_calculator/factories'
  factory :price_in_krw, parent: :price do
    variant
    amount 300000
    currency 'KRW'
  end
  factory :price_in_usd, parent: :price do
    variant
    amount 200
    currency 'USD'
  end

  factory :multi_currency_variant, parent: :base_variant do
    prices {
      Array[FactoryGirl.create(:price_in_krw),FactoryGirl.create(:price_in_usd)]
    }
  end

  factory :line_item_in_krw, parent: :line_item do
    price :price_in_krw
  end
end
