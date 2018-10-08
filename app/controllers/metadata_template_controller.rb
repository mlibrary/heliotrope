# frozen_string_literal: true

class MetadataTemplateController < ApplicationController
  def export
    exporter = Export::Exporter.new(nil)
    send_data exporter.blank_csv_sheet, type: 'text/csv; charset=utf-8; header=present', disposition: 'attachment; filename=fulcrum_blank_metadata.csv'
  end
end
