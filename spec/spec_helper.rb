# Run Coverage report
require 'simplecov'
SimpleCov.start do
  add_filter 'spec/dummy'
  add_group 'Libraries', 'lib'
end

# Configure Rails Environment
ENV['RAILS_ENV'] = 'test'

require File.expand_path('../dummy/config/environment.rb',  __FILE__)

require 'ffaker'
require 'rspec/rails'

Dir[File.join(File.dirname(__FILE__), 'support/**/*.rb')].each { |f| require f }

require 'spree/testing_support/factories'
require 'spree_currency_converter/factories'
require 'spree_korean_surface_mail_calculator/factories'
require 'spree/testing_support/preferences'

RSpec.configure do |config|
  config.mock_with :rspec
  config.color = true
  config.include Spree::TestingSupport::Preferences
  config.include FactoryGirl::Syntax::Methods
end
