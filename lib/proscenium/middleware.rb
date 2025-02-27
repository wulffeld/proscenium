# frozen_string_literal: true

module Proscenium
  class Middleware
    extend ActiveSupport::Autoload

    # Error when the build command fails.
    class BuildError < StandardError; end

    autoload :Base
    autoload :Esbuild
    autoload :Url

    def initialize(app)
      @app = app
    end

    def call(env)
      request = Rack::Request.new(env)

      return @app.call(env) if !request.get? && !request.head?

      attempt(request) || @app.call(env)
    end

    private

    def attempt(request)
      return unless (type = find_type(request))

      # file_handler.attempt(request.env) || type.attempt(request)

      type.attempt request
    end

    def find_type(request)
      return Url if request.path.match?(%r{^/https?%3A%2F%2F})
      return Esbuild if Pathname.new(request.path).fnmatch?(path_glob, File::FNM_EXTGLOB)
    end

    def path_glob
      paths = Rails.application.config.proscenium.include_paths.join(',')
      "/{#{paths}}/**.{#{FILE_EXTENSIONS.join(',')}}"
    end

    # TODO: handle precompiled assets
    # def file_handler
    #   ::ActionDispatch::FileHandler.new Rails.public_path.join('assets').to_s,
    #                                     headers: { 'X-Proscenium-Middleware' => 'precompiled' }
    # end
  end
end
