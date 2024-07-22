# frozen_string_literal: true

require 'semantic_logger'

SemanticLogger.add_appender(io: $stdout, formatter: :color)

class MarcLogger
  include SemanticLogger::Loggable

  self.logger = SemanticLogger.add_appender(
    file_name: Rails.root.join('log', 'marc.log').to_s,
    formatter: :color
  )
end
