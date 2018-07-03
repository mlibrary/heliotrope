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
    # See https://tools.lib.umich.edu/jira/browse/HELIO-1376?focusedCommentId=897580&page=com.atlassian.jira.plugin.system.issuetabpanels%3Acomment-tabpanel#comment-897580
    ["EPubsController", "Hyrax::FileSetsController", "Hyrax::DownloadsController"]
  end

  def self.allowed_presenters
    # I'm not actually sure we'll ever count anything monograph related.
    # If we do, add the controller and presenter
    ["Hyrax::FileSetPresenter"]
  end

  def count(opts = {})
    @controller.current_institutions.each do |institution|
      cr = CounterReport.new(session: session,
                             institution: institution.identifier,
                             noid: @presenter.id,
                             model: @presenter.has_model)
      # An "investigation" means to "view" (more or less)
      # A "request" means to "download" (mostly)
      # But when you log a "request", you also need to log an "investigation"
      # So "investigation" is always true.
      cr.investigation = 1
      cr.section = opts[:section]           if opts[:section]
      cr.section_type = opts[:section_type] if opts[:section_type]
      cr.request = 1                        if opts[:request]
      cr.turnaway = "No_License"            if opts[:turnaway]
      cr.access_type = access_type

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
    # For epubs, if they are restricted
    if Component.find_by(handle: HandleService.path(@presenter.id))
      "Controlled"
    # For assets if they have a permissions_expiration_date at any time, past of present
    elsif @presenter&.permissions_expiration_date.present?
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
