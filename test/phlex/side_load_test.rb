# frozen_string_literal: true

require_relative '../test_helper'

class Proscenium::Phlex::SideLoadTest < ActiveSupport::TestCase
  include Phlex::Testing::Rails::ViewHelper

  setup do
    Proscenium.reset_current_side_loaded
  end

  test 'side load component js and css' do
    render Phlex::SideLoadView.new

    assert_equal({
                   js: Set['/app/components/phlex/side_load_view.js'],
                   css: Set['/app/components/phlex/side_load_view.css']
                 }, Proscenium::Current.loaded)
  end

  test 'nested side load' do
    render Phlex::NestedSideLoadView.new

    assert_equal({
                   js: Set['/app/components/phlex/side_load_view.js'],
                   css: Set['/app/components/phlex/nested_side_load_view.css',
                            '/app/components/phlex/side_load_view.css']
                 }, Proscenium::Current.loaded)
  end

  test 'should side load css module' do
    view = render Phlex::SideLoadCssModuleView.new

    assert_equal('<div class="basebd9b41e5"></div>', view)
    assert_equal({
                   js: Set[],
                   css: Set['/app/components/phlex/side_load_css_module_view.module.css']
                 }, Proscenium::Current.loaded)
  end
end
