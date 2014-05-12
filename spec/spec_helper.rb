# Run Coverage report
require 'simplecov'
SimpleCov.start do
  add_filter '/spec/'
  add_filter '/lib/spree_korean_surface_mail/engine'
  add_group 'Libraries', 'lib'
end

# Configure Rails Environment
ENV['RAILS_ENV'] = 'test'

require File.expand_path('../dummy/config/environment.rb',  __FILE__)

require 'rspec/rails'
require 'ffaker'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[File.join(File.dirname(__FILE__), 'support/**/*.rb')].each { |f| require f }

# Requires factories defined in spree_core
require 'spree/testing_support/factories'

RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods

  config.mock_with :rspec
  config.color = true
  config.use_transactional_fixtures = true
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fail_fast = ENV['FAIL_FAST'] || false
end
