require 'spec_helper'

describe Spree::Calculator::KoreanSurfaceMail do
  let(:korean_surface_mail_calculator) { described_class.new }

  describe 'return description' do
    specify do
      expect(korean_surface_mail_calculator.description).to eq '선편요금'
    end
  end

  describe 'when the price is under 200,000 won (defaults)' do
    context '#compute:' do
      it 'returns a price of 13,300 won when the weight is under 2kg' do
        create_our_order(weight: 1.0, price: 10000, quantity: 1)
        result = korean_surface_mail_calculator.compute(@order)
        expect(result).to eq(13300)
      end

      it 'returns a shipping cost of 17,800 when the weight is between 2-4kg' do
        create_our_order(weight: 2.5, price: 10000, quantity: 1)
        result = korean_surface_mail_calculator.compute(@order)
        expect(result).to eq(17800)
      end

      it 'returns a shipping cost of 22,300 won when the weight is between 4-6kg' do
        create_our_order(weight: 5.5, price: 10000, quantity: 1)
        result = korean_surface_mail_calculator.compute(@order)
        expect(result).to eq(22300)
      end

      it 'returns a shipping cost of 26,700 won when the weight is between 6-8kg' do
        create_our_order(weight: 7.00, price: 10000, quantity: 1)
        result = korean_surface_mail_calculator.compute(@order)
        expect(result).to eq(26700)
      end

      it 'returns a shipping cost of 31,300 won when the weight is between 8-10kg' do
        create_our_order(weight: 9.00, price: 10000, quantity: 1)
        result = korean_surface_mail_calculator.compute(@order)
        expect(result).to eq(31300)
      end

      it 'returns a shipping cost of 35,700 won when the weight is between 10-12kg' do
        create_our_order(weight: 11.00, price: 10000, quantity: 1)
        result = korean_surface_mail_calculator.compute(@order)
        expect(result).to eq(35700)
      end

      it 'returns a shipping cost of 40,200 won when the weight is between 12-14kg' do
        create_our_order(weight: 13.00, price: 10000, quantity: 1)
        result = korean_surface_mail_calculator.compute(@order)
        expect(result).to eq(40200)
      end

      it 'returns a shipping cost of 44,700 won when the weight is between 14-16kg' do
        create_our_order(weight: 15.00, price: 10000, quantity: 1)
        result = korean_surface_mail_calculator.compute(@order)
        expect(result).to eq(44700)
      end

      it 'returns a shipping cost of 49,200 won when the weight is between 16-18kg' do
        create_our_order(weight: 17.00, price: 10000, quantity: 1)
        result = korean_surface_mail_calculator.compute(@order)
        expect(result).to eq(49200)
      end

      it 'returns a shipping cost of 53,600 won when the weight is between 18-20kg' do
        create_our_order(weight: 19.00, price: 10000, quantity: 1)
        result = korean_surface_mail_calculator.compute(@order)
        expect(result).to eq(53600)
      end

      it 'doesn\'t apply when the weight is over 20kg' do
        create_our_order(weight: 25.00, price: 10000, quantity: 1)
        result = korean_surface_mail_calculator.compute(@order)
        expect(result).to eq(0.0)
      end
    end
  end

  describe 'when the price is over 200,000 won (defaults)' do
    it 'returns a shipping cost of 27,000 won when the weight is under 1kg' do

    end

    it 'returns a shipping cost of 41,500 won when the weight is between 1-2kg' do

    end

    it 'returns a shipping cost of 51,000 won when the weight is between 2-3kg' do

    end

    it 'returns a shipping cost of 57,000 won when the weight is between 3-4kg' do

    end

    it 'returns a shipping cost of 63,000 won when the weight is between 4-5kg' do

    end

    it 'returns a shipping cost of 69,000 won when the weight is between 5-6kg' do

    end

    it 'returns a shipping cost of 75,000 won when the weight is between 6-7kg' do

    end

    it 'returns a shipping cost of 81,000 won when the weight is between 7-8kg' do
    end

    it 'returns a shipping cost of 87,000 won when the weight is between 8-9kg' do

    end

    it 'returns a shipping cost of 93,000 won when the weight is between 9-10kg' do

    end

    it 'returns a shipping cost of 99,000 won when the weight is between 10-11kg' do

    end

    it 'returns a shipping cost of 105,000 won when the weight is between 11-12kg' do

    end

    it 'returns a shipping cost of 111,000 won when the weight is between 12-13kg' do

    end

    it 'returns a shipping cost of 117,000 won when the weight is between 13-14kg' do

    end

    it 'returns a shipping cost of 123,000 won when the weight is between 14-15kg' do

    end

    it 'returns a shipping cost of 129,000 won when the weight is between 15-16kg' do

    end

    it 'returns a shipping cost of 135,000 won when the weight is between 16-17kg' do

    end

    it 'returns a shipping cost of 141,000 won when the weight is between 17-18kg' do

    end

    it 'returns a shipping cost of 147,000 won when the weight is between 18-19kg' do

    end

    it 'returns a shipping cost of 153,000 won when the weight is between 19-20kg' do

    end

    it 'returns a shipping cost of 159,000 won when the weight is between 20-21kg' do

    end

    it 'returns a shipping cost of 165,000 won when the weight is between 21-22kg' do

    end

    it 'returns a shipping cost of 171,000 won when the weight is between 22-23kg' do

    end

    it 'returns a shipping cost of 177,000 won when the weight is between 23-24kg' do

    end

    it 'returns a shipping cost of 183,000 won when the weight is between 24-25kg' do

    end

    it 'returns a shipping cost of 189,000 won when the weight is between 24-26kg' do

    end

    it 'returns a shipping cost of 195,000 won when the weight is between 26-27kg' do
    end

    it 'returns a shipping cost of 201,000 won when the weight is between 27-28kg' do

    end

    it 'returns a shipping cost of 207,000 won when the weight is between 28-29kg' do

    end

    it 'returns a shipping cost of 213,000 won when the weight is between 29-30kg' do

    end

    it 'doesn\'t apply when the weight is over 30kg' do

    end

  end

  def create_our_order(args={})
    params = {}
    params.merge!(weight: args[:weight]) if args[:weight]
    params.merge!(height: args[:height]) if args[:height]
    params.merge!(width:  args[:width])  if args[:width]
    params.merge!(depth:  args[:depth])  if args[:depth]
    @variant = create(:base_variant, params)

    params = { variant: @variant }
    params.merge!(price: args[:price]) if args[:price]
    params.merge!(quantity: args[:quantity]) if args[:quantity]
    @line_item = create(:line_item, params)

    @order = @line_item.order
    @order.line_items.reload

  end
end
