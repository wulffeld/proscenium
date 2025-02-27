# frozen_string_literal: true

require 'active_support/log_subscriber'

module Proscenium
  class LogSubscriber < ActiveSupport::LogSubscriber
    def sideload(event)
      info do
        "  [Proscenium] Side loaded #{event.payload[:identifier]}"
      end
    end

    def build(event)
      path = event.payload[:identifier]
      path = path.start_with?(/https?%3A%2F%2F/) ? CGI.unescape(path) : path

      info do
        message = +"[Proscenium] Building #{path}"
        message << " (Duration: #{event.duration.round(1)}ms | Allocations: #{event.allocations})"
        message << "\n" if defined?(Rails.env) && Rails.env.development?
      end
    end
  end
end

Proscenium::LogSubscriber.attach_to :proscenium
