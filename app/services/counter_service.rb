# frozen_string_literal: true

class CounterService
  attr_reader :controller, :presenter

  def self.from(controller, presenter)
    return null_object(controller, presenter) unless allowed_controllers.include? controller.class.name
    return null_object(controller, presenter) unless allowed_presenters.include? presenter.class.name

    new(controller, presenter)
  end

  def self.for_press(controller, press)
    return null_object(controller, nil, press) unless /PressCatalogController/.match?(controller.class.name)
    return null_object(controller, nil, press) if press.blank?

    new(controller, nil, press)
  end

  def self.null_object(controller, presenter, press = nil)
    CounterServiceNullObject.new(controller, presenter, press)
  end

  def self.allowed_controllers
    ["EPubsController", "Hyrax::FileSetsController", "Hyrax::DownloadsController", "MonographCatalogController", "EmbedController", "EbooksController"]
  end

  def self.allowed_presenters
    ["Hyrax::FileSetPresenter", "Hyrax::MonographPresenter"]
  end

  def count(opts = {}) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    return if @presenter&.visibility == "restricted"
    # Filter Institutions: LIT/Staff IP or monitoring IP, HELIO-4090; LOCKSS/CLOCKSS or Google Scholar, HELIO-4122
    return if (@controller.current_institutions.map(&:identifier) & ["490", "2405", "2334", "2402"]).present?

    # Add "Unknown Institution" (aka: "The World") if the request has no institutions and is not a robot
    if @controller.current_institutions.empty? && !robot?
      world_institution = Greensub::Institution.where(identifier: Settings.world_institution_identifier).first
      @controller.current_institutions.push(world_institution) if world_institution.present?
    end

    # Add a COUNT for each institution. Usually a request will only have a single
    # institution, but not always (for instance: U of M and LIT IP ranges means 2 institutions)
    @controller.current_institutions.each do |institution|
      cr = CounterReport.new(session: session,
                             institution: institution.identifier,
                             noid: @presenter&.id,
                             model: @presenter&.has_model)

      case @presenter&.has_model
      when 'FileSet'
        cr.parent_noid = @presenter&.monograph_id
        cr.press = Press.where(subdomain: @presenter.parent.subdomain).first&.id
      when 'Monograph'
        # A Monograph's parent_noid is itself to make some kinds of reporting easier
        cr.parent_noid = @presenter.id
        cr.press = Press.where(subdomain: @presenter.subdomain).first&.id
      end
      cr.press ||= @press&.id

      cr.access_type = access_type if @press.blank?
      cr.access_type ||= 'Controlled'

      cr.investigation = 1                  if !opts[:search]
      cr.section = opts[:section]           if opts[:section]
      cr.section_type = opts[:section_type] if opts[:section_type]
      cr.request = 1                        if opts[:request]
      cr.turnaway = "No_License"            if opts[:turnaway]
      cr.search = 1                         if opts[:search]
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

  def access_type # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
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

    oa   = if @presenter.is_a? Hyrax::MonographPresenter
             @presenter.open_access?
           else
             @presenter.parent.open_access?
           end
    if Greensub::Component.find_by(noid: noid) && !oa
      "Controlled"
      # For assets if they have a permissions_expiration_date at any time, past or present
    elsif @presenter.is_a?(Hyrax::FileSetPresenter) && @presenter&.permissions_expiration_date.present?
      "Controlled"
    else
      "OA_Gold"
    end
  end

  def robot?
    return true if @controller.request.user_agent.blank? # No user_agent is suspect...

    robots_list.each do |pattern|
      # One of the bot patterns in the list COUNTER provides has a bad regex:
      #   warning: regular expression has ']' without escape: /^Mozilla\/4\.5\+\[en]\+\(Win98;\+I\)$/
      # TODO: Submit a pull request to the https://github.com/atmire/COUNTER-Robots/ project. But for now, silence the warning.
      silence_warnings do
        return true if @controller.request.user_agent.match?(/#{pattern}/i)
      end
    end
    false
  end

  def robots_list
    Rails.cache.fetch(RecacheCounterRobotsJob::RAILS_CACHE_KEY, expires_in: 7.days) do
      # The plan is to have a cron fetch and cache the robots list nightly, so the following won't happen in normal usage.
      RecacheCounterRobotsJob.new.download_json unless File.exist? RecacheCounterRobotsJob::JSON_FILE
      # First cache the list for next time, then return the list
      RecacheCounterRobotsJob.new.cache_pattern_list
      RecacheCounterRobotsJob.new.load_list
    end
  end

  private

    def initialize(controller, presenter, press = nil)
      @controller = controller
      @presenter = presenter
      @press = press
    end
end

class CounterServiceNullObject < CounterService
  def initialize(controller, presenter, press = nil)
    @controller = controller
    @presenter = presenter
    @press = press
  end

  def count(_opts = {})
    Rails.logger.error("Can't use CounterService for #{@controller.class.name} or #{@presenter.class.name}")
  end
end
