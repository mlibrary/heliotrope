# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Marc::Validator do
  describe "#valid?" do
    context "the happy path, everything validates" do
      let(:doi) { "10.3998/mpub.10209707" }
      let(:noid) { "999999999" }
      let!(:monograph) { create(:public_monograph, press: "leverpress", id: noid, title: ["Something"], doi: doi) }
      let(:component) { create(:component, identifier: 'someid or doi or noid or something', name: 'something', noid: noid) }
      let(:product) { create(:product, identifier: 'leverpress', name: 'name', purchase: 'purchase', needs_kbart: true, group_key: 'leverpress') }

      before do
        product.components << component
        product.save!
      end

      context ".mrc format" do
        let(:marc_file) { Rails.root.join('spec', 'fixtures', 'marc', 'valid_marc.mrc').to_s }

        it "validates" do
          validator = described_class.new(marc_file)
          record = validator.reader.first

          expect(validator.ruby_marc_valid?(record)).to be true
          expect(validator.valid_024?(record)).to be true
          expect(validator.exists_in_fulcrum?(record)).to be true
          expect(validator.valid_001?(record)).to be true
          expect(validator.valid_003?(record)).to be true
          expect(validator.valid_020?(record)).to be true
          expect(validator.valid_856?(record)).to be true

          expect(validator.valid?).to be true

          # We hold onto the noid and groupkey. When validating a single marc
          # record having the Validator remember them could be useful in the future
          expect(validator.noid).to eq noid
          expect(validator.group_key).to eq "leverpress"
        end
      end

      context "xml" do
        let(:marc_file) { Rails.root.join('spec', 'fixtures', 'marc', 'valid_marc.xml').to_s }

        it "validates" do
          expect(described_class.new(marc_file).valid?).to be true
        end
      end
    end
  end

  describe "#ruby_marc_valid?" do
    # this comes with ruby marc. I don' think it actually does much in this context, maybe it's more for when
    # you write marc, not read it. I've never seen it NOT validate something. Seems like it might be
    # worth looking into more someday.
    # https://github.com/ruby-marc/ruby-marc/blob/c7604d0878169846c4e1dd66e460a58c1053be97/lib/marc/record.rb#L125-L133
    let(:marc_file) { Rails.root.join('spec', 'fixtures', 'marc', 'valid_marc.xml').to_s }

    context "valid marc" do
      it "returns true" do
        validator = described_class.new(marc_file)
        record = validator.reader.first
        expect(validator.ruby_marc_valid?(record)).to be true
      end
    end

    context "not valid" do
      let(:record) { double("record", valid?: false, errors: ['An error message I guess']) }
      it "logs an error, returns false" do
        validator = described_class.new(marc_file)
        expect(MarcLogger.logger).to receive(:error).twice
        expect(validator.ruby_marc_valid?(record)).to be false
      end
    end
  end

  describe "#valid_024?" do
    context "valid marc" do
      let(:marc_file) { Rails.root.join('spec', 'fixtures', 'marc', 'valid_marc.xml').to_s }
      it "returns true" do
        validator = described_class.new(marc_file)
        record = validator.reader.first
        expect(validator.valid_024?(record)).to be true
      end
    end

    context "missing 024" do
      let(:marc_file) { Rails.root.join('spec', 'fixtures', 'marc', '024_missing.xml').to_s }
      it "returns false" do
        validator = described_class.new(marc_file)
        record = validator.reader.first
        expect(MarcLogger.logger).to receive(:error)
        expect(validator.valid_024?(record)).to be false
      end
    end

    context "bad doi in 024" do
      let(:marc_file) { Rails.root.join('spec', 'fixtures', 'marc', '024_bad_doi.xml').to_s }
      it "returns true" do
        # We only care if 024$a is missing, not if it's wrong. That's a different validation
        validator = described_class.new(marc_file)
        record = validator.reader.first
        expect(validator.valid_024?(record)).to be true
      end
    end
  end

  describe "#exists_in_fulcrum?" do
    context "valid marc" do
      let(:marc_file) { Rails.root.join('spec', 'fixtures', 'marc', 'valid_marc.xml').to_s }
      let(:noid) { "999999999" }
      let(:component) { double("component", products: [product]) }
      let(:product) { double("product", group_key: "leverpress") }

      before do
        allow(Greensub::Component).to receive(:find_by).and_return(component)
        allow(ActiveFedora::SolrService).to receive(:query).and_return([{ "id" => noid }])
      end

      it "returns true" do
        validator = described_class.new(marc_file)
        record = validator.reader.first
        expect(validator.exists_in_fulcrum?(record)).to be true
      end
    end

    context "has a handle in 024$a but not a doi" do
      let(:marc_file) { Rails.root.join('spec', 'fixtures', 'marc', '024_handle_instead_of_doi.xml').to_s }
      let(:noid) { "999999999" }
      let(:component) { double("component", products: [product]) }
      let(:product) { double("product", group_key: "leverpress") }
      let(:hdl_row) { double("hdl_row", url_value: "https://www.fulcrum.org/concern/monograph/#{noid}") }

      before do
        allow(Greensub::Component).to receive(:find_by).and_return(component)
        allow(ActiveFedora::SolrService).to receive(:query).and_return([{}])
        allow(HandleDeposit).to receive(:where).and_return([hdl_row])
      end

      it "returns true" do
        validator = described_class.new(marc_file)
        record = validator.reader.first
        expect(validator.exists_in_fulcrum?(record)).to be true
      end
    end

    context "024$a doi/hdl is not in fulcrum" do
      let(:marc_file) { Rails.root.join('spec', 'fixtures', 'marc', '024_bad_doi.xml').to_s }

      it "returns false" do
        validator = described_class.new(marc_file)
        record = validator.reader.first
        expect(MarcLogger.logger).to receive(:error)
        expect(validator.exists_in_fulcrum?(record)).to be false
      end
    end

    context "monograph has no component" do
      let(:marc_file) { Rails.root.join('spec', 'fixtures', 'marc', 'valid_marc.xml').to_s }
      let(:noid) { "999999999" }

      before do
        allow(ActiveFedora::SolrService).to receive(:query).and_return([{ "id" => noid }])
      end

      it "returns false" do
        validator = described_class.new(marc_file)
        record = validator.reader.first
        expect(MarcLogger.logger).to receive(:error)
        expect(validator.exists_in_fulcrum?(record)).to be false
      end
    end

    context "monograph component is in no products" do
      let(:marc_file) { Rails.root.join('spec', 'fixtures', 'marc', 'valid_marc.xml').to_s }
      let(:noid) { "999999999" }
      let(:component) { double("component", products: []) }

      before do
        allow(Greensub::Component).to receive(:find_by).and_return(component)
        allow(ActiveFedora::SolrService).to receive(:query).and_return([{ "id" => noid }])
      end

      it "returns false" do
        validator = described_class.new(marc_file)
        record = validator.reader.first
        expect(MarcLogger.logger).to receive(:error)
        expect(validator.exists_in_fulcrum?(record)).to be false
      end
    end

    context "component is in multiple products and has more than one group_key" do
      # This should not happen. It will mess things up if it does. We do have examples of the same book being in both
      # bigten and michigan (umpebc) for example, however we've duplicated the monograph so it's in the repo twice, once
      # as bigten and once as michigan. So the bigten book has it's own component and the michigan book has it's own component.
      # No monograph should have more than one group_key at this point in time.
      let(:marc_file) { Rails.root.join('spec', 'fixtures', 'marc', 'valid_marc.xml').to_s }
      let(:noid) { "999999999" }
      let(:component) { double("component", products: [product1, product2]) }
      let(:product1) { double("product", group_key: "leverpress") }
      let(:product2) { double("product", group_key: "amherst") }

      before do
        allow(Greensub::Component).to receive(:find_by).and_return(component)
        allow(ActiveFedora::SolrService).to receive(:query).and_return([{ "id" => noid }])
      end

      it "returns false" do
        validator = described_class.new(marc_file)
        record = validator.reader.first
        expect(MarcLogger.logger).to receive(:error)
        expect(validator.exists_in_fulcrum?(record)).to be false
      end
    end
  end

  describe "#valid_001?" do
    context "valid marc" do
      let(:marc_file) { Rails.root.join('spec', 'fixtures', 'marc', 'valid_marc.xml').to_s }

      it "returns true" do
        validator = described_class.new(marc_file)
        record = validator.reader.first
        expect(validator.valid_001?(record)).to be true
      end
    end

    context "missing 001 field" do
      let(:marc_file) { Rails.root.join('spec', 'fixtures', 'marc', '001_missing.xml').to_s }

      it "returns false" do
        validator = described_class.new(marc_file)
        record = validator.reader.first
        expect(MarcLogger.logger).to receive(:error)
        expect(validator.valid_001?(record)).to be false
      end
    end

    context "001 field contains an OCLC number" do
      let(:marc_file) { Rails.root.join('spec', 'fixtures', 'marc', '001_has_oclc_number.xml').to_s }

      it "returns false" do
        validator = described_class.new(marc_file)
        record = validator.reader.first
        expect(MarcLogger.logger).to receive(:error)
        expect(validator.valid_001?(record)).to be false
      end
    end
  end

  describe "#valid_003?" do
    context "valid marc" do
      let(:marc_file) { Rails.root.join('spec', 'fixtures', 'marc', 'valid_marc.xml').to_s }

      it "returns true" do
        validator = described_class.new(marc_file)
        record = validator.reader.first
        expect(validator.valid_003?(record)).to be true
      end
    end

    context "missing 003" do
      let(:marc_file) { Rails.root.join('spec', 'fixtures', 'marc', '003_missing.xml').to_s }

      it "returns false" do
        validator = described_class.new(marc_file)
        record = validator.reader.first
        expect(MarcLogger.logger).to receive(:error)
        expect(validator.valid_003?(record)).to be false
      end
    end

    context "bad 003" do
      # This happens fairly often it's usually a weird whitespace character that I assume comes out of MarcEdit
      let(:marc_file) { Rails.root.join('spec', 'fixtures', 'marc', '003_bad_value.xml').to_s }

      it "returns false" do
        validator = described_class.new(marc_file)
        record = validator.reader.first
        expect(MarcLogger.logger).to receive(:error)
        expect(validator.valid_003?(record)).to be false
      end
    end

    context "a BAR group_key" do
      let(:noid) { "999999999" }
      let(:component) { double("component", products: [product]) }
      let(:product) { double("product", group_key: "bar") }

      before do
        allow(Greensub::Component).to receive(:find_by).and_return(component)
        allow(ActiveFedora::SolrService).to receive(:query).and_return([{ "id" => noid }])
      end

      context "a BAR 003 field" do
        let(:marc_file) { Rails.root.join('spec', 'fixtures', 'marc', '003_bar.xml').to_s }

        it "returns true" do
          validator = described_class.new(marc_file)
          record = validator.reader.first
          # need to set the group_key here
          validator.exists_in_fulcrum?(record)
          expect(validator.valid_003?(record)).to be true
        end
      end

      context "a MiU field" do
        let(:marc_file) { Rails.root.join('spec', 'fixtures', 'marc', 'valid_marc.xml').to_s }

        it "returns false" do
          validator = described_class.new(marc_file)
          record = validator.reader.first
          # need to set the group_key here
          validator.exists_in_fulcrum?(record)
          expect(MarcLogger.logger).to receive(:error)
          expect(validator.valid_003?(record)).to be false
        end
      end
    end
  end

  describe "#valid_020?" do
    context "valid marc" do
      let(:marc_file) { Rails.root.join('spec', 'fixtures', 'marc', 'valid_marc.xml').to_s }

      it "returns true" do
        validator = described_class.new(marc_file)
        record = validator.reader.first
        expect(validator.valid_020?(record)).to be true
      end
    end

    context "missing 020" do
      let(:marc_file) { Rails.root.join('spec', 'fixtures', 'marc', '020_missing.xml').to_s }

      it "returns false" do
        validator = described_class.new(marc_file)
        record = validator.reader.first
        expect(MarcLogger.logger).to receive(:error)
        expect(validator.valid_020?(record)).to be false
      end
    end
  end

  describe "#valid_856?" do
    context "valid marc" do
      let(:marc_file) { Rails.root.join('spec', 'fixtures', 'marc', 'valid_marc.xml').to_s }

      it "returns true" do
        validator = described_class.new(marc_file)
        record = validator.reader.first
        expect(validator.valid_856?(record)).to be true
      end
    end

    context "missing 856" do
      let(:marc_file) { Rails.root.join('spec', 'fixtures', 'marc', '856_missing.xml').to_s }

      it "returns false" do
        validator = described_class.new(marc_file)
        record = validator.reader.first
        expect(MarcLogger.logger).to receive(:error)
        expect(validator.valid_856?(record)).to be false
      end
    end

    context "missing 856$u" do
      let(:marc_file) { Rails.root.join('spec', 'fixtures', 'marc', '856u_missing.xml').to_s }

      it "returns false" do
        validator = described_class.new(marc_file)
        record = validator.reader.first
        expect(MarcLogger.logger).to receive(:error)
        expect(validator.valid_856?(record)).to be false
      end
    end
  end
end
