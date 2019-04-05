# frozen_string_literal: true

class SushiService
  def initialize(customer_id, platform, requestor_id)
    @customer_id = customer_id
    @platform = platform
    @requestor_id = requestor_id
  end

  def status
    fulcrum_status = ::SwaggerClient::SUSHIServiceStatus.new
    fulcrum_status.description = "COUNTER Usage Reports for Fulcrum platform."
    fulcrum_status.service_active = true
    fulcrum_status.registry_url = Rails.application.routes.url_helpers.api_sushi_url
    fulcrum_status.note = "You must be a platform administrator to retrieve reports."
    can_read = ::SwaggerClient::SUSHIServiceStatusAlerts.new
    can_read.alert = "If you can read this ..."
    can_read.date_time = DateTime.now.to_f  # rubocop:disable Style/DateTime
    too_close = ::SwaggerClient::SUSHIServiceStatusAlerts.new
    too_close.alert = "You are too CLOSE!"
    too_close.date_time = DateTime.now.to_f # rubocop:disable Style/DateTime
    fulcrum_status.alerts = [can_read, too_close]
    [fulcrum_status]
  end

  def members
    member = ::SwaggerClient::SUSHIConsortiumMemberList.new
    member.customer_id = @customer_id
    member.requestor_id = User.find(@requestor_id)&.email
    member.name = Greensub::Institution.find(@customer_id).name
    member.notes = Greensub::Institution.find(@customer_id).entity_id
    member.institution_id = []
    [member]
  end

  def reports(_search = nil)
    platform_master_report = ::SwaggerClient::SUSHIReportList.new
    platform_master_report.report_name = 'Platform Master Report'
    platform_master_report.report_id = 'PR'
    platform_master_report.release = '5'
    platform_master_report.report_description = 'A customizable report that summarizes activity across a provider’s platforms and allows the user to apply filters and select other configuration options.'
    platform_master_report.path = Rails.application.routes.url_helpers.api_sushi_report_url(:pr)

    platform_usage = ::SwaggerClient::SUSHIReportList.new
    platform_usage.report_name = 'Platform Usage'
    platform_usage.report_id = 'PR_P1'
    platform_usage.release = '5'
    platform_usage.report_description = 'A Standard View of the Platform Master Report offering platform-level usage summarized by metric type.'
    platform_usage.path = Rails.application.routes.url_helpers.api_sushi_report_url(:pr_p1)

    # TODO: Filter reports by search parameter

    [platform_master_report, platform_usage]
  end

  def report(id)
    # Attribute mapping from ruby-style variable name to JSON key.
    # def self.attribute_map
    #   {
    #       :'created' => :'Created',
    #       :'created_by' => :'Created_By',
    #       :'customer_id' => :'Customer_ID',
    #       :'report_id' => :'Report_ID',
    #       :'release' => :'Release',
    #       :'report_name' => :'Report_Name',
    #       :'institution_name' => :'Institution_Name',
    #       :'institution_id' => :'Institution_ID',
    #       :'report_filters' => :'Report_Filters',
    #       :'report_attributes' => :'Report_Attributes',
    #       :'exceptions' => :'Exceptions'
    #   }
    # end
    report_header = ::SwaggerClient::SUSHIReportHeader.new

    # case id
    # when /dr|dr_d1|dr_d2/i
    #   :'report_items' => :'Array<COUNTERDatabaseUsage>'
    # when /ir|ir_a1|ir_m1/i
    #   :'report_items' => :'Array<COUNTERItemUsage>'
    # when /pr|pr_p1/i
    #   :'report_items' => :'Array<COUNTERPlatformUsage>'
    # when /tr|tr_b1|tr_b2|tr_b3|tr_j1|tr_j2|tr_j3|tr_j4/i
    #   :'report_items' => :'Array<COUNTERTitleUsage>'
    # end
    #
    report_items = []

    # Attribute mapping from ruby-style variable name to JSON key.
    # def self.attribute_map
    #   {
    #       :'report_header' => :'Report_Header',
    #       :'report_items' => :'Report_Items'
    #   }
    # end
    attributes = { Report_Header: report_header, Report_Items: report_items }

    case id
    when /dr|dr_d1|dr_d2/i
      ::SwaggerClient::COUNTERDatabaseReport
    when /ir|ir_a1|ir_m1/i
      ::SwaggerClient::COUNTERItemReport
    when /pr|pr_p1/i
      ::SwaggerClient::COUNTERPlatformReport
    when /tr|tr_b1|tr_b2|tr_b3|tr_j1|tr_j2|tr_j3|tr_j4/i
      ::SwaggerClient::COUNTERTitleReport
    end.new(attributes)
  end
end
