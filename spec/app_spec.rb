# frozen_string_literal: true

require_relative '../app'
require 'pry'
require 'capybara'
require 'capybara/rspec'
require 'capybara-screenshot/rspec'
require 'selenium/webdriver'

Capybara.app = App
Capybara.server = :webrick
Capybara::Screenshot.prune_strategy = :keep_last_run
Capybara.save_path = 'tmp'
Capybara.register_driver :remote_chrome do |app|
  Capybara::Selenium::Driver.new(
    app,
    browser: :remote,
    url: 'http://localhost:4444/wd/hub',
    desired_capabilities: :chrome
  )
end

Capybara.configure do |config|
  config.default_driver = :rack_test
  config.javascript_driver = :remote_chrome
  config.app_host = 'http://host.docker.internal:9292'
  config.server_host = '0.0.0.0'
  config.server_port = 9292
end

describe '/search', type: :feature, js: true do
  it 'fills in the search model input' do
    visit '/'
    page.click_on 'Launch demo modal'

    within('#exampleModal') do
      search = page.find('input[name=search]')
      search.fill_in with: 'A bunch of gibberish'
      expect(search.value).to eq('A bunch of gibberish')
    end
  end
end
