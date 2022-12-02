# frozen_string_literal: true

require 'open3'
require 'oj'

module Proscenium
  class Middleware
    class Base
      include ActiveSupport::Benchmarkable

      # Error when the result of the build returns an error. For example, when esbuild returns
      # errors.
      class CompileError < StandardError
        attr_reader :detail, :file

        def initialize(args)
          @detail = args[:detail]
          @file = args[:file]
          super "Failed to build '#{args[:file]}' -- #{detail}"
        end
      end

      def self.attempt(request)
        new(request).renderable!&.attempt
      end

      def initialize(request)
        @request = request
      end

      def renderable!
        renderable? ? self : nil
      end

      private

      def sourcemap?
        @request.path.ends_with?('.map')
      end

      def renderable?
        sourcemap? ? file_readable?(@request.path[0...-4]) : file_readable?
      end

      def file_readable?(file = @request.path_info)
        return unless (path = clean_path(file))

        file_stat = File.stat(Pathname(root).join(path.delete_prefix('/').b).to_s)
      rescue SystemCallError
        false
      else
        file_stat.file? && file_stat.readable?
      end

      def clean_path(file)
        path = Rack::Utils.unescape_path file.chomp('/').delete_prefix('/')
        Rack::Utils.clean_path_info path if Rack::Utils.valid_path? path
      end

      def root
        @root ||= Rails.root.to_s
      end

      def content_type
        @content_type ||
          ::Rack::Mime.mime_type(::File.extname(@request.path_info), nil) ||
          'application/javascript'
      end

      def render_response(content)
        response = Rack::Response.new
        response.write content
        response.content_type = content_type
        response['X-Proscenium-Middleware'] = name
        response.set_header 'SourceMap', "#{@request.path_info}.map"

        if Proscenium.config.cache_query_string && Proscenium.config.cache_max_age
          response.cache! Proscenium.config.cache_max_age
        end

        yield response if block_given?

        response.finish
      end

      def build(cmd)
        stdout, stderr, status = Open3.capture3(cmd)

        if !status.success? || !stderr.empty?
          raise self.class::CompileError, { file: @request.fullpath, detail: stderr }, caller
        end

        stdout
      end

      def benchmark(type)
        super logging_message(type)
      end

      # rubocop:disable Style/FormatStringToken
      def logging_message(type)
        format '[Proscenium] Request (%s) %s for %s at %s',
               type, @request.fullpath, @request.ip, Time.now.to_default_s
      end
      # rubocop:enable Style/FormatStringToken

      def logger
        Rails.logger
      end

      def name
        @name ||= self.class.name.split('::').last.downcase
      end
    end
  end
end
