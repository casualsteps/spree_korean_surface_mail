require 'spec_helper'

describe Spree::Calculator::KoreanSurfaceMail do
  let(:korean_surface_mail_calculator) { described_class.new }
  let(:korean_surface_mail_calculator_usd_limit) { described_class.new(:preferred_limit_currency => 'USD', :preferred_lower_price_bracket_minimum => 200, :preferred_lower_price_bracket_limit => 200) }

  describe 'return description' do
    specify do
      expect(korean_surface_mail_calculator.description).to eq 'Korean customs tax (관세 + 부가세)'
    end
  end

  describe 'when the limit currency is 200 USD' do
    context '#compute:' do
      it 'returns a tax of 70,835 (rounded up to the nearest whole "won") KRW when the weight is between 1-2kg' do
        create_our_order(weight: 330.693, price: 300000, quantity: 1, currency: 'USD')
        expect(korean_surface_mail_calculator_usd_limit.preferred_limit_currency).to eq('USD')
        result = korean_surface_mail_calculator_usd_limit.compute(@order)
        expect(result).to eq(79461)
      end
    end
  end

  describe 'when the price is 250,000 won' do
    context '#compute:' do
      it 'returns a tax of 70,835 (rounded up to nearest whole "won" from 70,384.5) KRW when weight is between 1-2kg' do
        create_our_order(weight: 330.693, price: 250000, quantity: 1)
        result = korean_surface_mail_calculator.compute(@order)
        expect(result).to eq(70835.0)
      end
    end
    # TODO: Add more test specs based on real past orders
  end

  describe 'when the price is under 200,000 won (defaults)' do
    context '#calculate_seonpyeonyogeum:' do
      it 'returns a price of 13,300 won when the weight is under 2kg' do
        create_our_order(weight: 220.462, price: 10000, quantity: 1)
        result = korean_surface_mail_calculator.calculate_seonpyeonyogeum(@order)
        expect(result).to eq(13300)
      end

      it 'returns a shipping cost of 17,800 when the weight is between 2-4kg' do
        create_our_order(weight: 551.156, price: 10000, quantity: 1)
        result = korean_surface_mail_calculator.calculate_seonpyeonyogeum(@order)
        expect(result).to eq(17800)
      end

      it 'returns a shipping cost of 22,300 won when the weight is between 4-6kg' do
        create_our_order(weight: 1212.54, price: 10000, quantity: 1)
        result = korean_surface_mail_calculator.calculate_seonpyeonyogeum(@order)
        expect(result).to eq(22300)
      end

      it 'returns a shipping cost of 26,700 won when the weight is between 6-8kg' do
        create_our_order(weight: 1543.24, price: 10000, quantity: 1)
        result = korean_surface_mail_calculator.calculate_seonpyeonyogeum(@order)
        expect(result).to eq(26700)
      end

      it 'returns a shipping cost of 31,300 won when the weight is between 8-10kg' do
        create_our_order(weight: 1873.93, price: 10000, quantity: 1)
        result = korean_surface_mail_calculator.calculate_seonpyeonyogeum(@order)
        expect(result).to eq(31300)
      end

      it 'returns a shipping cost of 35,700 won when the weight is between 10-12kg' do
        create_our_order(weight: 2425.08, price: 10000, quantity: 1)
        result = korean_surface_mail_calculator.calculate_seonpyeonyogeum(@order)
        expect(result).to eq(35700)
      end

      it 'returns a shipping cost of 40,200 won when the weight is between 12-14kg' do
        create_our_order(weight: 2866.01, price: 10000, quantity: 1)
        result = korean_surface_mail_calculator.calculate_seonpyeonyogeum(@order)
        expect(result).to eq(40200)
      end

      it 'returns a shipping cost of 44,700 won when the weight is between 14-16kg' do
        create_our_order(weight: 3306.93, price: 10000, quantity: 1)
        result = korean_surface_mail_calculator.calculate_seonpyeonyogeum(@order)
        expect(result).to eq(44700)
      end

      it 'returns a shipping cost of 49,200 won when the weight is between 16-18kg' do
        create_our_order(weight: 3747.86, price: 10000, quantity: 1)
        result = korean_surface_mail_calculator.calculate_seonpyeonyogeum(@order)
        expect(result).to eq(49200)
      end

      it 'returns a shipping cost of 53,600 won when the weight is between 18-20kg' do
        create_our_order(weight: 4188.78, price: 10000, quantity: 1)
        result = korean_surface_mail_calculator.calculate_seonpyeonyogeum(@order)
        expect(result).to eq(53600)
      end

      it 'doesn\'t apply when the weight is over 20kg' do
        create_our_order(weight: 5511.56, price: 10000, quantity: 1)
        result = korean_surface_mail_calculator.calculate_seonpyeonyogeum(@order)
        expect(result).to eq(0.0)
      end
    end
  end

  describe 'when the price is over 200,000 won (defaults)' do
    it 'returns a shipping cost of 27,000 won when the weight is under 1kg' do
      create_our_order(weight: 198.416, price: 200000, quantity: 1)
      result = korean_surface_mail_calculator.calculate_seonpyeonyogeum(@order)
      expect(result).to eq(27000)
    end

    it 'returns a shipping cost of 41,500 won when the weight is between 1-2kg' do
      create_our_order(weight: 330.693, price: 200000, quantity: 1)
      result = korean_surface_mail_calculator.calculate_seonpyeonyogeum(@order)
      expect(result).to eq(41500)
    end

    it 'returns a shipping cost of 51,000 won when the weight is between 2-3kg' do
      create_our_order(weight: 551.156, price: 200000, quantity: 1)
      result = korean_surface_mail_calculator.calculate_seonpyeonyogeum(@order)
      expect(result).to eq(51000)
    end

    it 'returns a shipping cost of 57,000 won when the weight is between 3-4kg' do
      create_our_order(weight: 771.618, price: 200000, quantity: 1)
      result = korean_surface_mail_calculator.calculate_seonpyeonyogeum(@order)
      expect(result).to eq(57000)
    end

    it 'returns a shipping cost of 63,000 won when the weight is between 4-5kg' do
      create_our_order(weight: 992.08, price: 200000, quantity: 1)
      result = korean_surface_mail_calculator.calculate_seonpyeonyogeum(@order)
      expect(result).to eq(63000)
    end

    it 'returns a shipping cost of 69,000 won when the weight is between 5-6kg' do
      create_our_order(weight: 1212.54, price: 200000, quantity: 1)
      result = korean_surface_mail_calculator.calculate_seonpyeonyogeum(@order)
      expect(result).to eq(69000)
    end

    it 'returns a shipping cost of 75,000 won when the weight is between 6-7kg' do
      create_our_order(weight: 1433.00, price: 200000, quantity: 1)
      result = korean_surface_mail_calculator.calculate_seonpyeonyogeum(@order)
      expect(result).to eq(75000)
    end

    it 'returns a shipping cost of 81,000 won when the weight is between 7-8kg' do
      create_our_order(weight: 1653.47, price: 200000, quantity: 1)
      result = korean_surface_mail_calculator.calculate_seonpyeonyogeum(@order)
      expect(result).to eq(81000)
    end

    it 'returns a shipping cost of 87,000 won when the weight is between 8-9kg' do
      create_our_order(weight: 1873.93, price: 200000, quantity: 1)
      result = korean_surface_mail_calculator.calculate_seonpyeonyogeum(@order)
      expect(result).to eq(87000)
    end

    it 'returns a shipping cost of 93,000 won when the weight is between 9-10kg' do
      create_our_order(weight: 2094.39, price: 200000, quantity: 1)
      result = korean_surface_mail_calculator.calculate_seonpyeonyogeum(@order)
      expect(result).to eq(93000)
    end

    it 'returns a shipping cost of 99,000 won when the weight is between 10-11kg' do
      create_our_order(weight: 2314.854, price: 200000, quantity: 1)
      result = korean_surface_mail_calculator.calculate_seonpyeonyogeum(@order)
      expect(result).to eq(99000)
    end

    it 'returns a shipping cost of 105,000 won when the weight is between 11-12kg' do
      create_our_order(weight: 2535.316, price: 200000, quantity: 1)
      result = korean_surface_mail_calculator.calculate_seonpyeonyogeum(@order)
      expect(result).to eq(105000)
    end

    it 'returns a shipping cost of 111,000 won when the weight is between 12-13kg' do
      create_our_order(weight: 2755.778, price: 200000, quantity: 1)
      result = korean_surface_mail_calculator.calculate_seonpyeonyogeum(@order)
      expect(result).to eq(111000)
    end

    it 'returns a shipping cost of 117,000 won when the weight is between 13-14kg' do
      create_our_order(weight: 2976.241, price: 200000, quantity: 1)
      result = korean_surface_mail_calculator.calculate_seonpyeonyogeum(@order)
      expect(result).to eq(117000)
    end

    it 'returns a shipping cost of 123,000 won when the weight is between 14-15kg' do
      create_our_order(weight: 3196.703, price: 200000, quantity: 1)
      result = korean_surface_mail_calculator.calculate_seonpyeonyogeum(@order)
      expect(result).to eq(123000)
    end

    it 'returns a shipping cost of 129,000 won when the weight is between 15-16kg' do
      create_our_order(weight: 3417.165, price: 200000, quantity: 1)
      result = korean_surface_mail_calculator.calculate_seonpyeonyogeum(@order)
      expect(result).to eq(129000)
    end

    it 'returns a shipping cost of 135,000 won when the weight is between 16-17kg' do
      create_our_order(weight: 3637.627, price: 200000, quantity: 1)
      result = korean_surface_mail_calculator.calculate_seonpyeonyogeum(@order)
      expect(result).to eq(135000)
    end

    it 'returns a shipping cost of 141,000 won when the weight is between 17-18kg' do
      create_our_order(weight: 3858.09, price: 200000, quantity: 1)
      result = korean_surface_mail_calculator.calculate_seonpyeonyogeum(@order)
      expect(result).to eq(141000)
    end

    it 'returns a shipping cost of 147,000 won when the weight is between 18-19kg' do
      create_our_order(weight: 4078.552, price: 200000, quantity: 1)
      result = korean_surface_mail_calculator.calculate_seonpyeonyogeum(@order)
      expect(result).to eq(147000)
    end

    it 'returns a shipping cost of 153,000 won when the weight is between 19-20kg' do
      create_our_order(weight: 4299.014, price: 200000, quantity: 1)
      result = korean_surface_mail_calculator.calculate_seonpyeonyogeum(@order)
      expect(result).to eq(153000)
    end

    it 'returns a shipping cost of 159,000 won when the weight is between 20-21kg' do
      create_our_order(weight: 4519.476, price: 200000, quantity: 1)
      result = korean_surface_mail_calculator.calculate_seonpyeonyogeum(@order)
      expect(result).to eq(159000)
    end

    it 'returns a shipping cost of 165,000 won when the weight is between 21-22kg' do
      create_our_order(weight: 4739.939, price: 200000, quantity: 1)
      result = korean_surface_mail_calculator.calculate_seonpyeonyogeum(@order)
      expect(result).to eq(165000)
    end

    it 'returns a shipping cost of 171,000 won when the weight is between 22-23kg' do
      create_our_order(weight: 4960.401, price: 200000, quantity: 1)
      result = korean_surface_mail_calculator.calculate_seonpyeonyogeum(@order)
      expect(result).to eq(171000)
    end

    it 'returns a shipping cost of 177,000 won when the weight is between 23-24kg' do
      create_our_order(weight: 5180.863, price: 200000, quantity: 1)
      result = korean_surface_mail_calculator.calculate_seonpyeonyogeum(@order)
      expect(result).to eq(177000)
    end

    it 'returns a shipping cost of 183,000 won when the weight is between 24-25kg' do
      create_our_order(weight: 5401.325, price: 200000, quantity: 1)
      result = korean_surface_mail_calculator.calculate_seonpyeonyogeum(@order)
      expect(result).to eq(183000)
    end

    it 'returns a shipping cost of 189,000 won when the weight is between 24-26kg' do
      create_our_order(weight: 5621.788, price: 200000, quantity: 1)
      result = korean_surface_mail_calculator.calculate_seonpyeonyogeum(@order)
      expect(result).to eq(189000)
    end

    it 'returns a shipping cost of 195,000 won when the weight is between 26-27kg' do
      create_our_order(weight: 5842.25, price: 200000, quantity: 1)
      result = korean_surface_mail_calculator.calculate_seonpyeonyogeum(@order)
      expect(result).to eq(195000)
    end

    it 'returns a shipping cost of 201,000 won when the weight is between 27-28kg' do
      create_our_order(weight: 6062.712, price: 200000, quantity: 1)
      result = korean_surface_mail_calculator.calculate_seonpyeonyogeum(@order)
      expect(result).to eq(201000)
    end

    it 'returns a shipping cost of 207,000 won when the weight is between 28-29kg' do
      create_our_order(weight: 6283.174, price: 200000, quantity: 1)
      result = korean_surface_mail_calculator.calculate_seonpyeonyogeum(@order)
      expect(result).to eq(207000)
    end

    it 'returns a shipping cost of 213,000 won when the weight is between 29-30kg' do
      create_our_order(weight: 6503.637, price: 200000, quantity: 1)
      result = korean_surface_mail_calculator.calculate_seonpyeonyogeum(@order)
      expect(result).to eq(213000)
    end

    it 'doesn\'t apply when the weight is over 30kg' do
      create_our_order(weight: 6622.6864, price: 200000, quantity: 1)
      result = korean_surface_mail_calculator.calculate_seonpyeonyogeum(@order)
      expect(result).to eq(0)
    end
  end

  def create_our_order(args={})
    Spree::Config[:currency] = 'KRW'
    params = {}
    params.merge!(weight: args[:weight]) if args[:weight]
    params.merge!(height: args[:height]) if args[:height]
    params.merge!(width:  args[:width])  if args[:width]
    params.merge!(depth:  args[:depth])  if args[:depth]
    if args[:currency]
      @variant = create(:multi_currency_variant)
      puts @variant.to_json
    else
      @variant = create(:base_variant, params)
    end

    params = { variant: @variant }
    params.merge!(quantity: args[:quantity]) if args[:quantity]
    params.merge!(price: args[:price]) if args[:price]
    @line_item = create(:line_item_in_krw, params)
    @order = @line_item.order
    @order.line_items.reload
    @order.update!
  end
end
