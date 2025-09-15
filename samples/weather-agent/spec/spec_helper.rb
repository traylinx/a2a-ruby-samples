# frozen_string_literal: true

require "bundler/setup"
require "rspec"
require "webmock/rspec"
require "vcr"
require "pry"

# Configure WebMock
WebMock.disable_net_connect!(allow_localhost: true)

# Configure VCR for API testing
VCR.configure do |config|
  config.cassette_library_dir = "spec/vcr_cassettes"
  config.hook_into :webmock
  config.configure_rspec_metadata!
  config.default_cassette_options = { record: :once }
  
  # Filter sensitive data
  config.filter_sensitive_data('<WEATHER_API_KEY>') { ENV['WEATHER_API_KEY'] }
end

# Configure RSpec
RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.example_status_persistence_file_path = "spec/examples.txt"
  config.disable_monkey_patching!
  config.warnings = true

  if config.files_to_run.one?
    config.default_formatter = "doc"
  end

  config.profile_examples = 10
  config.order = :random
  Kernel.srand config.seed

  # Set up test environment
  config.before(:suite) do
    ENV['WEATHER_API_KEY'] ||= 'test_api_key'
    ENV['WEATHER_CACHE_TTL'] = '0' # Disable caching in tests
  end
end