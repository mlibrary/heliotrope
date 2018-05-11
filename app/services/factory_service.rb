# frozen_string_literal: true

require_dependency 'valid'
require_dependency 'e_pub'
require_dependency 'webgl'

module FactoryService # rubocop:disable Metrics/ModuleLength
  #
  # Singleton Pattern
  #
  @monitor ||= Monitor.new
  @monitor.synchronize do
    @semaphores ||= Hash.new { |hash, key| hash[key] = Mutex.new }
    @e_pub_publication_cache ||= Hash.new { { publication: EPub::Publication.null_object, time: Time.now } }
    @webgl_unity_cache ||= Hash.new { { unity: Webgl::Unity.null_object, time: Time.now } }
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
      clear_webgl_unity_cache
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

  def self.clear_webgl_unity_cache
    @monitor.synchronize do
      @webgl_unity_cache.each do |id, hash|
        @semaphores[id].synchronize do
          hash[:unity].purge
        end
        @semaphores.delete(id)
      end
      @webgl_unity_cache.clear
      Webgl::Unity.clear_cache
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

  def self.purge_webgl_unity(id)
    Rails.logger.info("FactoryService.purge_webgl_unity(#{id}) \'#{id}\' is not a noid.") unless Valid.noid?(id)
    return unless Valid.noid?(id)

    @monitor.synchronize do
      @semaphores[id].synchronize do
        hash = @webgl_unity_cache.delete(id)
        hash[:unity].purge if hash.present?
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

  def self.webgl_unity(id)
    Rails.logger.info("FactoryService.webgl_unity(#{id}) \'#{id}\' is NOT a valid noid.") unless Valid.noid?(id)
    return Webgl::Unity.null_object unless Valid.noid?(id)

    semaphore(id).synchronize do
      unity = if @webgl_unity_cache.key?(id)
                @webgl_unity_cache[id][:unity]
              else
                webgl_unity_from(id)
              end
      @webgl_unity_cache[id] = { unity: unity, time: Time.now } unless unity.instance_of?(Webgl::UnityNullObject)
      unity
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

    def self.create_epub_webgl_bridge(id)
      epub_fr = FeaturedRepresentative.where(file_set_id: id).first
      if FeaturedRepresentative.where(monograph_id: epub_fr.monograph_id, kind: 'webgl')&.first.present?
        true
      else
        false
      end
    end
    private_class_method :create_epub_webgl_bridge

    def self.webgl_unity_from(id)
      presenter = Hyrax::PresenterFactory.build_for(ids: [id], presenter_class: Hyrax::FileSetPresenter, presenter_args: nil).first
      return Webgl::Unity.null_object if presenter.nil?
      return Webgl::Unity.null_object unless presenter.webgl?
      file = Tempfile.new(id)
      file.write(presenter.file.content.force_encoding("utf-8"))
      file.close
      Webgl::Unity.from(id: id, file: file.path)
    rescue StandardError => e
      Rails.logger.info("FactoryService.webgl_unity_from(#{id}) raised #{e}")
      Webgl::Unity.null_object
    end
    private_class_method :webgl_unity_from
end
