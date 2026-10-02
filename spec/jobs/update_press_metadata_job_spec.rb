# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UpdatePressMetadataJob, type: :job do
  describe "#perform" do
    # Create the relational SQL records
    let(:parent_press) { create(:press, subdomain: 'michigan') }
    let(:press) { create(:press, name: 'Original Press Name', subdomain: 'orig-sub', parent: parent_press) }

    # Create mock ActiveFedora models. We skip standard hooks to manually manage their state
    let(:monograph) { double('Monograph', id: 'mono123') }
    let(:file_set) { double('FileSet', id: 'file456') }

    before do
      # Mock the ActiveRecord lookup and eager loading
      allow(Press).to receive(:includes).with(:parent).and_return(Press)
      allow(Press).to receive(:find_by).with(subdomain: 'orig-sub').and_return(press)
      allow(Press).to receive(:find_by).with(subdomain: 'new-sub').and_return(press)

      # Handle mock arrays for search lookups
      allow(monograph).to receive(:file_sets).and_return([file_set])

      # Mock Solr interactions to avoid hitting a live external network service
      allow(ActiveFedora::SolrService).to receive(:add)
      allow(ActiveFedora::SolrService).to receive(:commit)
    end

    context "when only the press name changes (Scenario B)" do
      before do
        # 1. Create a mock relation or double that responds to find_each
        monograph_relation = double('ActiveFedora::Relation')
        allow(monograph_relation).to receive(:find_each).with(batch_size: 100).and_yield(monograph)

        # 2. Return that mock relation from the .where query lookup
        allow(Monograph).to receive(:where).with(press_sim: 'orig-sub').and_return(monograph_relation)

        allow(monograph).to receive(:to_solr).and_return({ 'id' => 'mono123', 'press_name_ssim' => 'New Press Name' })
      end

      it "updates the Solr documents directly without writing to Fedora" do
        described_class.perform_now(subdomain: 'orig-sub', name_changed: true, subdomain_changed: false)

        expect(monograph.instance_variable_get(:@preloaded_press_object)).to eq(press)
        expect(ActiveFedora::SolrService).to have_received(:add).with([{ 'id' => 'mono123', 'press_name_ssim' => 'New Press Name' }])
        expect(ActiveFedora::SolrService).to have_received(:commit)

        expect(monograph).not_to receive(:press=)
        expect(monograph).not_to receive(:save)
      end
    end

    context "when the press subdomain changes (Scenario A)" do
      before do
        # 1. Apply the same fix here to handle the batch processing block safely
        monograph_relation = double('ActiveFedora::Relation')
        allow(monograph_relation).to receive(:find_each).with(batch_size: 100).and_yield(monograph)

        allow(Monograph).to receive(:where).with(press_sim: 'old-sub').and_return(monograph_relation)

        allow(monograph).to receive(:press=)
        allow(monograph).to receive(:save)
        allow(file_set).to receive(:to_solr).and_return({ 'id' => 'file456', 'press_sim' => 'new-sub' })
      end

      it "performs a full ActiveFedora save and cascades changes to child FileSets" do
        press.subdomain = 'new-sub'

        described_class.perform_now(
          subdomain: 'new-sub',
          old_subdomain: 'old-sub',
          subdomain_changed: true,
          name_changed: false
        )

        expect(monograph).to have_received(:press=).with('new-sub')
        expect(monograph.instance_variable_get(:@preloaded_press_object)).to eq(press)
        expect(monograph).to have_received(:save)

        expect(file_set.instance_variable_get(:@monograph)).to eq(monograph)
        expect(ActiveFedora::SolrService).to have_received(:add).with({ 'id' => 'file456', 'press_sim' => 'new-sub' })
        expect(ActiveFedora::SolrService).to have_received(:commit)
      end
    end
  end
end
