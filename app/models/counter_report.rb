# frozen_string_literal: true

class CounterReport < ApplicationRecord
  # COUNTER v5 section 3.3.5
  validates :access_type, inclusion: { in: %w[Controlled OA_Gold] }

  # We probably won't use Limit_Exceeded but it's allowed
  # COUNTER v5 section 3.3.4
  validates :turnaway, inclusion: { in: [nil, "", "No_License", "Limit_Exceeded"] }

  # Really we only want "Chapter" here for the foreseeable future.
  # COUNTER v5 section 3.3.3
  # We'll use the higher level "Data_Type" for other things (which we can infer
  # from solr so we don't need to collect it in this table)
  # COUNTER v5 section 3.3.2
  validates :section_type, inclusion: { in: [nil, "", "Article", "Book", "Chapter", "Other", "Section"] }

  # Every record should have a corresponding press id
  validates :press, presence: true

  # HELIO-3070: truncate section to 255 characters so MySQL doesn't get irked
  before_save :truncate_section

  scope :unique, -> { select(:session, :noid).distinct }
  scope :unique_by_title, -> { select(:session, :parent_noid).distinct }
  scope :investigations, -> { where(investigation: 1) }
  scope :requests, -> { where(request: 1) }
  scope :searches, -> { where(search: 1) }
  scope :controlled, -> { where(access_type: 'Controlled') }

  scope :institution, ->(institution_id) { where(institution: institution_id) unless institution_id == '*' }

  def self.press(press_id)
    # HELIO-3659 COUNTER reports will include a presses children if there are any
    where(press: [press_id] + Press.where(parent: press_id).map(&:id))
  end

  def self.access_type(access_type)
    where(access_type: access_type)
  end

  def self.start_date(start_date)
    where("created_at > ?", start_date.beginning_of_month)
  end

  def self.end_date(end_date)
    where("created_at < ?", end_date.end_of_month)
  end

  def self.turnaway(turnaway = nil)
    where(turnaway: turnaway)
  end

  def truncate_section
    self.section = self.section.truncate(255) if self.section.present?
  end
end
