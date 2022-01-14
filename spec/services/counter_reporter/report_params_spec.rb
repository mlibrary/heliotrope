# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CounterReporter::ReportParams do
  let(:press) { create(:press) }

  context "a pr_p1 report" do
    subject { described_class.new('pr_p1', params) }

    let(:params) do
      {
        start_date: "2018-01-01",
        end_date: "2018-12-31",
        press: press.id,
        institution: '1'
      }
    end

    it "has the correct title" do
      expect(subject.report_title).to eq 'Platform Usage'
    end

    it "has the correct metric types" do
      expect(subject.metric_types).to contain_exactly('Searches_Platform', 'Total_Item_Requests', 'Unique_Item_Requests', 'Unique_Title_Requests')
    end

    it "has the correct access_type" do
      expect(subject.access_types).to contain_exactly('Controlled')
    end

    it "has the correct access_method" do
      expect(subject.access_methods).to contain_exactly('Regular')
    end
  end

  context "a tr_b1 report" do
    subject { described_class.new('tr_b1', params) }

    let(:params) do
      {
        start_date: "2018-01-01",
        end_date: "2018-12-31",
        press: press.id,
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
        press: press.id,
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
    context "with no press" do
      let(:item_params) { described_class.new('ir', params) }
      let(:params) do
        {
          metric_types: %w[Total_Item_Investigations],
          data_types: %w[Book],
          access_types: %w[Controlled],
          access_methods: %w[Regular],
          institution: 1
        }
      end

      it "does not validate" do
        expect(item_params.validate!).to be false
      end

      it 'has errors' do
        item_params.validate!
        expect(item_params.errors).to eq ['You must provide a Press']
      end
    end

    context "with no institution" do
      let(:title_params) { described_class.new('tr', params) }
      let(:params) do
        {
          metric_types: %w[Unique_Title_Requests],
          data_types: %w[Book],
          access_types: %w[Controlled],
          access_methods: %w[Regular],
          press: press.id
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
          data_type: 'Book',
          access_type: 'Controlled',
          access_method: 'Regular',
          press: press.id
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
          metric_type: 'Unique_Title_Requests',
          data_type: 'Book',
          access_type: '',
          access_method: 'Regular',
          press: press.id
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
