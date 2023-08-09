# frozen_string_literal: true

require 'rails_helper'
require 'import/row_data'

describe Import::RowData do
  let(:row_data) { described_class.new }
  let(:attrs) { {} }
  subject { row_data.field_values(object, row, attrs) }


  describe "open_access value is sanitized, only allowing 'yes'" do
    let(:object) { :monograph }

    context "value is 'yes'" do
      let(:row) { { 'Open Access?' => 'Yes' } }

      it 'allows' do
        subject
        expect(attrs['open_access']).to eq('yes')
      end
    end

    context "value is 'Yes'" do
      let(:row) { { 'Open Access?' => 'Yes' } }

      it 'downcases' do
        subject
        expect(attrs['open_access']).to eq('yes')
      end
    end

    context "value is 'no'" do
      let(:row) { { 'Open Access?' => 'no' } }

      it 'disallows' do
        subject
        expect(attrs['open_access']).to be_nil
      end
    end

    context "value is random junk" do
      let(:row) { { 'Open Access?' => 'BlaH!' } }

      it 'disallows' do
        subject
        expect(attrs['open_access']).to be_nil
      end
    end
  end

  describe "'Published?' value is sanitized, only allowing the relevant Hydra::AccessControls values" do
    let(:object) { :monograph }

    context "value is 'true'" do
      let(:row) { { 'Published?' => 'true' } }

      it 'converts to the public visibility value' do
        subject
        expect(attrs['visibility']).to eq(Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC)
      end
    end

    context "value is 'false'" do
      let(:row) { { 'Published?' => 'false' } }

      it 'converts to the private visibility value' do
        subject
        expect(attrs['visibility']).to eq(Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE)
      end
    end

    context "value is blank" do
      let(:row) { { 'Published?' => '' } }

      it 'disallows, returns `nil`' do
        subject
        expect(attrs['visibility']).to be_nil
      end
    end

    context "value is random junk" do
      let(:row) { { 'Published?' => 'BlaH!' } }

      it 'disallows, returns `nil`' do
        subject
        expect(attrs['visibility']).to be_nil
      end
    end
  end

  describe "newlines" do
    let(:object) { :monograph }

    context "metadata field with `newlines` unspecified" do
      context 'LF newlines present' do
        let(:row) { { 'Description' => "Line 1 \nLine 2  \nLine 3" } }

        it 'leaves the value unchanged' do
          subject
          expect(attrs['description']).to eq(["Line 1 \nLine 2  \nLine 3"])
        end
      end

      context 'CRLF newlines present' do
        let(:row) { { 'Description' => "Line 1 \r\n  Line 2\r\nLine 3" } }

        it 'leaves the value unchanged' do
          subject
          expect(attrs['description']).to eq(["Line 1 \r\n  Line 2\r\nLine 3"])
        end
      end
    end

    context "metadata field with `newlines: false`" do
      context 'LF newlines present' do
        let(:row) { { 'Title' => "Line 1 \nLine 2  \nLine 3" } }

        it 'joins the lines with a single space' do
          subject
          expect(attrs['title']).to eq(['Line 1 Line 2 Line 3'])
        end
      end

      context 'CRLF newlines present' do
        let(:row) { { 'Title' => "Line 1 \r\n  Line 2\r\nLine 3" } }

        it 'joins the lines with a single space' do
          subject
          expect(attrs['title']).to eq(['Line 1 Line 2 Line 3'])
        end
      end
    end
  end

  describe "old/alternate field name mapping using FIELD_NAME_MAP" do
    let(:object) { :monograph }

    context 'truly missing values (no `field_name` or `FIELD_NAME_MAP` values available)' do
      let(:row) { CSV::Row.new([], []) }

      it 'lets them be nil' do
        subject
        expect(attrs['rightsholder']).to eq(nil)
      end
    end

    context 'row has a `field_name` value *and* a `FIELD_NAME_MAP` value' do
      let(:row) { CSV::Row.new(['Copyright Holder', 'Rightsholder'], ['Copyright Holder Thingy', 'Rightsholder Thingy']) }

      it 'defers to the official/proper/current `field_name` (CSV header row) value' do
        subject
        expect(attrs['rightsholder']).to eq('Rightsholder Thingy')
      end
    end

    # this is by far the most likely use case when importing/processing old metadata CSV sheets
    context 'row only has a `FIELD_NAME_MAP` value' do
      let(:row) { CSV::Row.new(['Copyright Holder'], ['Copyright Holder Thingy']) }

      it 'uses the `FIELD_NAME_MAP` value for the corresponding `field_name` value' do
        subject
        expect(attrs['rightsholder']).to eq('Copyright Holder Thingy')
      end
    end
  end
end
