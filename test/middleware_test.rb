# frozen_string_literal: true

require_relative 'test_helper'

class MiddlewareTest < ActionDispatch::IntegrationTest
  test 'render files ending with .js' do
    get(path = '/app/views/layouts/application.js')

    assert_equal 'application/javascript', response.headers['Content-Type']
    assert_equal Rails.root.join(path[1..]).read, response.body
  end

  test 'build files ending with .jsx' do
    get '/lib/component.jsx'

    assert_equal 'application/javascript', response.headers['Content-Type']
    assert_matches_snapshot response.body
  end

  test 'stylesheet not found' do
    assert_raises ActionController::RoutingError do
      get '/notfound.css'
    end
  end

  test 'javascript not found' do
    assert_raises ActionController::RoutingError do
      get '/notfound.js'
    end
  end

  test 'build files ending with .css' do
    get '/app/views/layouts/application.css'

    assert_equal 'text/css', response.headers['Content-Type']
    assert_matches_snapshot response.body
  end
end
