# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CounterReporter::ReportParams do
  context "a tr_b1 report" do
    subject { described_class.new('tr_b1', params) }

    let(:params) do
      {
        start_date: "2018-01-01",
        end_date: "2018-12-31",
        press: '2',
        institution: '1'
      }
    end

    it "has the correct metric types" do
      expect(subject.metric_types).to eq ['Total_Item_Requests', 'Unique_Title_Requests']
    end

    it "has the correct title" do
      expect(subject.report_title).to eq 'Book Requests (Excluding OA_Gold)'
    end

    it "has the correct access_type" do
      expect(subject.access_types).to eq ['Controlled']
    end
  end

  context "a tr report" do
    subject { described_class.new('tr', params) }

    let(:params) do
      {
        start_date: "2018-01-01",
        end_date: "2018-12-31",
        press: '2',
        institution: '1',
        metric_type: 'Total_Item_Requests',
        access_type: 'OA_Gold',
        data_type: 'Book',
        access_method: 'Regular'
      }
    end

    it "has the correct metric type" do
      expect(subject.metric_types).to eq ['Total_Item_Requests']
    end

    it "has a start_date Date object" do
      expect(subject.start_date).to be_an_instance_of Date
    end

    it "has the correct access_type" do
      expect(subject.access_types).to eq ['OA_Gold']
    end
  end

  describe "#validate!" do
    context "with no institution" do
      let(:title_params) { described_class.new('tr', params) }
      let(:params) do
        {
          metric_type: 'Unique_Title_Requests',
          access_type: 'Controlled'
        }
      end

      it "does not validate" do
        expect(title_params.validate!).to be false
      end

      it "has errors" do
        title_params.validate!
        expect(title_params.errors).to eq ["You must provide an Institution"]
      end
    end

    context "with an incorrect metric_type" do
      let(:title_params) { described_class.new('tr', params) }
      let(:params) do
        {
          institution: '1',
          metric_type: 'Not_A_Thing',
          access_type: 'Controlled'
        }
      end

      it "does not validate" do
        expect(title_params.validate!).to be false
      end

      it "has errors" do
        title_params.validate!
        expect(title_params.errors).to eq ["Metric Type: 'Not_A_Thing' is not allowed"]
      end
    end

    context "with a missing access_type" do
      let(:title_params) { described_class.new('tr', params) }
      let(:params) do
        {
          institution: '1',
          metric_type: 'Unique_Title_Requests'
        }
      end

      it "does not validate" do
        expect(title_params.validate!).to be false
      end

      it "has errors" do
        title_params.validate!
        expect(title_params.errors).to eq ["Access Type: '' is not allowed"]
      end
    end
  end
end
