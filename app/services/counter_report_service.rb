# frozen_string_literal: true

class CounterReportService
  def initialize(customer_id, requestor_id)
    @sushi_service = SushiService.new(customer_id, 'fulcrum', requestor_id)
  end

  def active?
    @sushi_service.status&.first&.service_active || false
  end

  def description
    @sushi_service.status&.first&.description || ''
  end

  def note
    @sushi_service.status&.first&.note || ''
  end

  def alerts
    @sushi_service.status&.first&.alerts || []
  end

  def members
    @sushi_service.members || []
  end

  def reports
    @sushi_service.reports || []
  end

  def report(id)
    @sushi_service.report(id)
  end
end
