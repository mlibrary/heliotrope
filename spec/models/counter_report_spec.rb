# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CounterReport, type: :model do
  describe "validations" do
    it "only takes valid access_types" do
      expect(described_class.create(access_type: "No")).not_to be_valid
    end
    it "only takes valid turnaway" do
      expect(described_class.create(turnaway: "No")).not_to be_valid
    end
    it "ony takes valid section_type" do
      expect(described_class.create(section_type: "Magazine")).not_to be_valid
    end
  end

  describe "unique scope" do
    # unique is a distinct combination of session and noid
    before do
      create(:counter_report, session: 1, noid: 'a')
      create(:counter_report, session: 1, noid: 'b')
      create(:counter_report, session: 1, noid: 'a')
      create(:counter_report, session: 2, noid: 'a')
      create(:counter_report, session: 2, noid: 'c')
    end

    after { described_class.destroy_all }

    it do
      expect(described_class.unique.length).to eq 4
    end
  end

  describe "#press" do
    let(:press) { create(:press, subdomain: "blue") }
    let(:child) { create(:press, subdomain: "yellow", parent: press) }

    before do
      create(:counter_report, session: 1, noid: 'a', press: press.id)
      create(:counter_report, session: 2, noid: 'b', press: press.id)
      create(:counter_report, session: 3, noid: 'c', press: child.id)
    end

    it "returns that parent press and it's children" do
      expect(described_class.press(press).length).to eq 3
    end
  end

  describe "section name truncated to max 255 characters" do
    before do
      create(:counter_report, section: 'x' * 256)
    end

    after { described_class.destroy_all }

    it do
      expect(described_class.first.section.length).to eq 255
    end
  end

  describe "chained scopes/methods for a PR report" do
    before do
      create(:counter_report, session: 1, noid: 'a', parent_noid: 'A', institution: 1, created_at: Time.parse("2018-01-02").utc)
      create(:counter_report, session: 1, noid: 'a', parent_noid: 'A', institution: 1, created_at: Time.parse("2018-02-02").utc)
      create(:counter_report, session: 1, noid: 'b', parent_noid: 'B', institution: 1, created_at: Time.parse("2018-02-04").utc, request: 1)
      create(:counter_report, session: 1, noid: 'c', parent_noid: 'C', institution: 1, created_at: Time.parse("2018-11-11").utc)

      create(:counter_report, session: 2, noid: 'b', parent_noid: 'B', institution: 1, created_at: Time.parse("2018-02-02").utc)

      create(:counter_report, session: 3, noid: 'a', parent_noid: 'A', institution: 2, created_at: Time.parse("2018-02-01").utc)

      create(:counter_report, session: 4, noid: 'c', parent_noid: 'C', institution: 1, created_at: Time.parse("2018-02-02").utc, request: 1)
    end

    after { described_class.destroy_all }

    context "Total_Item_Investigations for Institution 1 in February" do
      it do
        expect(described_class.institution(1)
                              .investigations
                              .start_date(Date.parse("2018-02-01"))
                              .end_date(Date.parse("2018-02-28"))
                              .count).to eq 4
      end
    end

    context "Total_Item_Requests for Institution 1 in February" do
      it do
        expect(described_class.institution(1)
                              .requests
                              .start_date(Date.parse("2018-02-01"))
                              .end_date(Date.parse("2018-02-28"))
                              .count).to eq 2
      end
    end

    context "Unique_Item_Investigations for Instiution 1 in February" do
      it do
        expect(described_class.institution(1)
                            .investigations
                            .unique
                            .start_date(Date.parse("2018-02-01"))
                            .end_date(Date.parse("2018-02-28"))
                            .count).to eq 4
      end
    end

    context "Unique_Item_Requests for Institution 1 in February" do
      it do
        expect(described_class.institution(1)
                              .requests
                              .unique
                              .start_date(Date.parse("2018-02-01"))
                              .end_date(Date.parse("2018-02-28"))
                              .count).to eq 2
      end
    end

    context "Unique_Title_Investigations for Institution 1 in Feburary" do
      it do
        expect(described_class.institution(1)
                              .investigations
                              .unique_by_title
                              .start_date(Date.parse("2018-02-01"))
                              .end_date(Date.parse("2018-02-28"))
                              .count).to eq 4
      end
    end

    context "Unique_Title_Requests for Institution 1 in Feburary" do
      it do
        expect(described_class.institution(1)
                              .requests
                              .unique_by_title
                              .start_date(Date.parse("2018-02-01"))
                              .end_date(Date.parse("2018-02-28"))
                              .count).to eq 2
      end
    end
  end
end
