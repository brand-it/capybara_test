# frozen_string_literal: true

require 'bundler'
Bundler.require
Loader.autoload

# Entry Point for App
class App < Rack::App
  mount Application

  headers 'Access-Control-Allow-Origin' => '*'

  desc 'Search With Modal'
  get '/search' do
    File.read(File.expand_path('./index.html'))
  end

  root '/search'
end
