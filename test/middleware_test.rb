# frozen_string_literal: true

require_relative 'test_helper'

class MiddlewareTest < ActionDispatch::IntegrationTest
  setup do
    Proscenium.config.include_paths = Set.new(Proscenium::APPLICATION_INCLUDE_PATHS)
    Proscenium.config.cache_query_string = false
    Proscenium.config.css_mixin_paths = Set[Rails.root.join('lib')]
  end

  test 'unsupported path' do
    assert_raises ActionController::RoutingError do
      get '/db/some.js'
    end
  end

  test 'include_paths config' do
    Proscenium.config.include_paths << 'db'
    get '/db/some.js'

    assert_matches_snapshot response.body
  end

  test '.js' do
    get '/app/views/layouts/application.js'

    assert_equal 'application/javascript', response.headers['Content-Type']
    assert_equal 'esbuild', response.headers['X-Proscenium-Middleware']
    assert_matches_snapshot response.body
  end

  test '.jsx' do
    get '/lib/component.jsx'

    assert_equal 'application/javascript', response.headers['Content-Type']
    assert_equal 'esbuild', response.headers['X-Proscenium-Middleware']
    assert_matches_snapshot response.body
  end

  test '.css' do
    get '/app/views/layouts/application.css'

    assert_equal 'text/css', response.headers['Content-Type']
    assert_equal 'esbuild', response.headers['X-Proscenium-Middleware']
    assert_matches_snapshot response.body
  end

  test 'injects /lib/custom_media_queries.css if present' do
    get '/lib/with_custom_media.css'

    assert_equal 'text/css', response.headers['Content-Type']
    assert_equal 'esbuild', response.headers['X-Proscenium-Middleware']
    assert_matches_snapshot response.body
  end

  test '.module.css' do
    get '/lib/styles.module.css'

    assert_equal 'text/css', response.headers['Content-Type']
    assert_equal 'esbuild', response.headers['X-Proscenium-Middleware']
    assert_matches_snapshot response.body
  end

  test 'import css module from js' do
    get '/lib/import_css_module.js'

    assert_equal 'application/javascript', response.headers['Content-Type']
    assert_equal 'esbuild', response.headers['X-Proscenium-Middleware']
    assert_matches_snapshot response.body
  end

  test '/proscenium-runtime/auto_reload.js' do
    get '/proscenium-runtime/auto_reload.js'

    assert_equal 'application/javascript', response.headers['Content-Type']
    assert_equal 'runtime', response.headers['X-Proscenium-Middleware']
    refute_includes response.body, "from 'bundle:@rails/actioncable'"
  end

  test 'esbuild js compilation error' do
    get '/lib/includes_error.js'

    assert_equal 'application/javascript', response.headers['Content-Type']
    assert_equal 'esbuild', response.headers['X-Proscenium-Middleware']
    assert_matches_snapshot response.body
  end

  test 'source map' do
    get '/lib/foo.js.map'

    assert_equal 'application/javascript', response.headers['Content-Type']
    assert_equal 'esbuild', response.headers['X-Proscenium-Middleware']
    assert_matches_snapshot response.body
  end

  test 'jsx source map' do
    get '/lib/component.jsx.map'

    assert_equal 'application/javascript', response.headers['Content-Type']
    assert_equal 'esbuild', response.headers['X-Proscenium-Middleware']
    assert_matches_snapshot response.body
  end

  test 'node module (pnpm)' do
    get '/node_modules/is-ip/index.js'

    assert_equal 'application/javascript', response.headers['Content-Type']
    assert_equal 'esbuild', response.headers['X-Proscenium-Middleware']
    assert_matches_snapshot response.body
  end

  test 'cache_query_string should set cache header' do
    Proscenium.config.cache_query_string = 'v1'
    get '/lib/query_cache.js?v1'

    assert_includes response.headers['Cache-Control'], 'public'
  end

  test 'cache_query_string should propogate' do
    Proscenium.config.cache_query_string = 'v1'
    get '/lib/query_cache.js?v1'

    assert_matches_snapshot response.body
  end

  test 'CSS mixins' do
    get '/lib/with_mixins.css'

    assert_matches_snapshot response.body
  end

  test 'config.css_mixin_paths' do
    Proscenium.config.css_mixin_paths << Rails.root.join('config')
    get '/lib/with_mixins_from_alternative_path.css'

    assert_matches_snapshot response.body
  end
end
