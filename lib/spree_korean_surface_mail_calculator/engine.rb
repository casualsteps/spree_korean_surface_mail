module SpreeKoreanSurfaceMailCalculator
  class Engine < Rails::Engine
    isolate_namespace Spree
    engine_name 'spree_korean_surface_mail_calculator'

    config.autoload_paths += %W({#{config.root}/lib)

    initializer 'spree.register.calculators' do |app|
      require 'spree/calculator/shipping/korean_surface_mail'
      app.config.spree.calculators.tax_rates << Spree::Calculator::KoreanSurfaceMail
    end
  end
end
