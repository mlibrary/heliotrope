# frozen_string_literal: true

class MarcLogger
  def self.logger
    @logger ||= create_logger
  end

  def self.create_logger
    logger = Logger.new('log/marc.log', 'daily')
    logger.level = Logger::DEBUG
    logger
  end

  def self.info(message)
    logger.info(message)
  end

  def self.debug(message)
    logger.debug(message)
  end

  def self.error(message)
    logger.error(message)
  end

  private_class_method :create_logger
end
