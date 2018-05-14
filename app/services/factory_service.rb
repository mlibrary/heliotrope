# frozen_string_literal: true

require_dependency 'valid'
require_dependency 'e_pub'

module FactoryService
  #
  # Singleton Pattern
  #
  @monitor ||= Monitor.new
  @monitor.synchronize do
    @semaphores ||= Hash.new { |hash, key| hash[key] = Mutex.new }
    @e_pub_publication_cache ||= Hash.new { { publication: EPub::Publication.null_object, time: Time.now } }
  end

  #
  # No Operation
  #
  def self.nop; end

  #
  # Monitor Methods
  #
  def self.clear_semaphores
    @monitor.synchronize do
      @semaphores.each do |_id, semaphore|
        semaphore.synchronize do
          nop
        end
      end
      @semaphores.clear
    end
  end

  def self.clear_caches
    @monitor.synchronize do
      clear_e_pub_publication_cache
      clear_semaphores # Order dependent, must be called last!
    end
  end

  def self.clear_e_pub_publication_cache
    @monitor.synchronize do
      @e_pub_publication_cache.each do |id, hash|
        @semaphores[id].synchronize do
          hash[:publication].purge
        end
        @semaphores.delete(id)
      end
      @e_pub_publication_cache.clear
      EPub::Publication.clear_cache
    end
  end

  def self.purge_e_pub_publication(id)
    Rails.logger.info("FactoryService.purge_e_pub_publication(#{id}) \'#{id}\' is not a valid noid.") unless Valid.noid?(id)
    return unless Valid.noid?(id)

    @monitor.synchronize do
      @semaphores[id].synchronize do
        hash = @e_pub_publication_cache.delete(id)
        hash[:publication].purge if hash.present?
      end
      @semaphores.delete(id)
    end
  end

  #
  # Semaphore Methods
  #
  # Danger Will Robinson! ... Danger!
  #
  # To avoid dreadlocks, I mean deadlocks
  # do NOT call a monitor method
  # from inside a semaphore synchronize block!
  #
  # And it should go without saying but,
  # do NOT nest synchronize blocks.
  #
  def self.e_pub_publication(id)
    Rails.logger.info("FactoryService.e_pub_publication(#{id}) \'#{id}\' is NOT a valid noid.") unless Valid.noid?(id)
    return EPub::Publication.null_object unless Valid.noid?(id)

    semaphore(id).synchronize do
      publication = if @e_pub_publication_cache.key?(id)
                      @e_pub_publication_cache[id][:publication]
                    else
                      e_pub_publication_from(id)
                    end
      @e_pub_publication_cache[id] = { publication: publication, time: Time.now } unless publication.instance_of?(EPub::PublicationNullObject)
      publication
    end
  end

  private # rubocop:disable Lint/UselessAccessModifier

    #
    # Helper Methods
    #
    def self.semaphore(id)
      @monitor.synchronize do
        @semaphores[id]
      end
    end
    private_class_method :semaphore

    def self.e_pub_publication_from(id)
      presenter = Hyrax::PresenterFactory.build_for(ids: [id], presenter_class: Hyrax::FileSetPresenter, presenter_args: nil).first
      return EPub::Publication.null_object if presenter.nil?
      return EPub::Publication.null_object unless presenter.epub?
      file = Tempfile.new(id)
      file.write(presenter.file.content.force_encoding("utf-8"))
      file.close
      EPub::Publication.from(id: id, file: file.path, webgl: create_epub_webgl_bridge(id))
    rescue StandardError => e
      Rails.logger.info("FactoryService.e_pub_publication_from(#{id}) raised #{e}")
      EPub::Publication.null_object
    end
    private_class_method :e_pub_publication_from

    def self.create_epub_webgl_bridge(_id)
      false
    end
    private_class_method :create_epub_webgl_bridge
end
