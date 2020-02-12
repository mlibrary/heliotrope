# frozen_string_literal: true

class CounterService
  attr_reader :controller, :presenter

  def self.from(controller, presenter)
    return null_object(controller, presenter) unless allowed_controllers.include? controller.class.name
    return null_object(controller, presenter) unless allowed_presenters.include? presenter.class.name

    new(controller, presenter)
  end

  def self.null_object(controller, presenter)
    CounterServiceNullObject.new(controller, presenter)
  end

  def self.allowed_controllers
    ["EPubsController", "Hyrax::FileSetsController", "Hyrax::DownloadsController", "MonographCatalogController", "EmbedController", "EbooksController"]
  end

  def self.allowed_presenters
    ["Hyrax::FileSetPresenter", "Hyrax::MonographPresenter"]
  end

  def count(opts = {}) # rubocop:disable Metrics/CyclomaticComplexity
    return if @presenter&.visibility == "restricted"

    @controller.current_institutions.each do |institution|
      cr = CounterReport.new(session: session,
                             institution: institution.identifier,
                             noid: @presenter.id,
                             model: @presenter.has_model)

      case @presenter.has_model
      when 'FileSet'
        cr.parent_noid = @presenter&.monograph_id
        cr.press = Press.where(subdomain: @presenter.parent.subdomain).first&.id
      when 'Monograph'
        # A Monograph's parent_noid is itself to make some kinds of reporting easier
        cr.parent_noid = @presenter.id
        cr.press = Press.where(subdomain: @presenter.subdomain).first&.id
      end

      cr.access_type = access_type
      cr.investigation = 1
      cr.section = opts[:section]           if opts[:section]
      cr.section_type = opts[:section_type] if opts[:section_type]
      cr.request = 1                        if opts[:request]
      cr.turnaway = "No_License"            if opts[:turnaway]
      cr.save!
    end
  end

  def session
    ip   = @controller.request.remote_ip
    ua   = @controller.request.user_agent
    date = DateTime.now.strftime('%Y-%m-%d')
    hour = DateTime.now.hour
    # Per COUNTER v5 section 7.4, this is ok for session
    "#{ip}|#{ua}|#{date}|#{hour}"
  end

  def access_type
    # COUNTER v5 section 3.5.3 seems to indicate that we need this
    # for epubs as well as multimedia (TR and IR reports).
    # Currently, in Checkpoint, we are restricting at the Monograph level,
    # not the FileSet level. So we want to always use the Monograph to determine
    # access_type.
    noid = if @presenter.is_a? Hyrax::MonographPresenter
             @presenter.id
           else
             @presenter.parent.id
           end
    if Greensub::Component.find_by(noid: noid)
      "Controlled"
      # For assets if they have a permissions_expiration_date at any time, past or present
    elsif @presenter.is_a?(Hyrax::FileSetPresenter) && @presenter&.permissions_expiration_date.present?
      "Controlled"
    else
      "OA_Gold"
    end
  end

  private

    def initialize(controller, presenter)
      @controller = controller
      @presenter = presenter
    end
end

class CounterServiceNullObject < CounterService
  def initialize(controller, presenter)
    @controller = controller
    @presenter = presenter
  end

  def count(_opts = {})
    Rails.logger.error("Can't use CounterService for #{@controller.class.name} or #{@presenter.class.name}")
  end
end
