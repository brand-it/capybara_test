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

# Headless Chrome screenshots
Capybara::Screenshot.register_driver(:remote_chrome) do |driver, path|
  driver.browser.save_screenshot(path)
end

module Capybara
  module CustomMatchers
    class HaveFilledIn
      include Capybara::DSL
      extend Dry::Initializer
      param :locator
      option :with
      option :retries, default: -> { 2 }
      option :find_options, default: -> { {} }
      option :fill_options, default: -> { {} }

      def description
        "have filled in with #{locator} with #{with}"
      end

      def matches?(page)
        field = fillable_field(page)
        retry_until_filled(field) { field.set(with, fill_options) }
        field.value == with
      end

      def failure_message
        field = fillable_field(page)
        "expected that \"#{locator}\" would have filled in value of"\
        " \"#{with}\" but actually was \"#{field.value}\""
      end
      alias failure_message_when_negated failure_message

      private

      def fillable_field(page)
        page.find(:fillable_field, locator, find_options)
      end

      def retry_until_filled(field, &block)
        tries = 0
        until tries > retries || field.value == with
          yield block
          tries += 1
        end
      end
    end

    # From Time to Time, the fill_in method will fail to fill in the values.
    # In order to prevent flaky tests and more failure resistant,
    # this have _filled_in does a retry and a check to make sure the
    # value has filled incorrectly.
    #
    # expect(page).to have_filled_in('search', with: 'A bunch of gibberish')
    # expect(page).to have_filled_in(
    #   'search',
    #   with: 'A bunch of gibberish',
    #   retries: 2,
    #   find_options: { allow_self: true, with: 'All ready filled in' },
    #   fill_options: { clear: true }
    # )
    def have_filled_in(*args)
      HaveFilledIn.new(*args)
    end
  end
end

RSpec.configure do |config|
  config.include Capybara::CustomMatchers, type: :feature
end

describe '/search', type: :feature, js: true do
  it 'fills in the search model input' do
    visit '/'
    page.click_on 'Launch demo modal'

    within('#exampleModal') do
      expect(page).to have_filled_in('search', with: 'A bunch of gibberish')
    end
  end
end
