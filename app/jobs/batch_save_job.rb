# frozen_string_literal: true

class BatchSaveJob < ApplicationJob
  def perform(data)
    # Where data is:
    # { noid:
    #   {
    #     field: value,
    #     field: value,
    #   },
    #   ...
    # }
    # If there is a way to save 100s or 1000s of AF objects in a timely manner
    # instead of using a job I'd love to hear it.
    return if data.blank?

    data.each do |noid, values|
      entity = Sighrax.from_noid(noid)
      if entity.is_a?(Sighrax::Monograph)
        m = Monograph.find(noid)
        values.each do |k, v|
          m.send("#{k}=", v)
        end
        m.save!
      elsif entity.is_a?(Sighrax::Resource)
        f = FileSet.find(noid)
        values.each do |k, v|
          f.send("#{k}=", v)
        end
        f.save!
      end
    end
  end
end
