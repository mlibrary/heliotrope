require 'spec_helper'

describe Hydra::Works::FileSet do
  let(:file_set) { described_class.new }

  describe 'Related objects' do
    let(:object1) { Hydra::PCDM::Object.new }

    before do
      file_set.related_objects = [object1]
    end

    it 'persists' do
      expect(file_set.related_objects).to eq [object1]
    end
  end

  describe "#type" do
    it "returns Object and FileSet" do
      expect(subject.type).to contain_exactly(Hydra::PCDM::Vocab::PCDMTerms.Object, Hydra::Works::Vocab::WorksTerms.FileSet)
    end
  end

  describe '#files' do
    let(:file1) { file_set.files.build }
    let(:file2) { file_set.files.build }

    before do
      file_set.save!
      file1.content = "I'm a file"
      file2.content = 'I am too'
      file_set.save!
    end

    subject { described_class.find(file_set.id).files }

    it { is_expected.to contain_exactly(file1, file2) }
  end

  describe '#in_works' do
    subject { file_set.in_works }
    let(:work) { Hydra::Works::Work.create }
    before do
      work.ordered_members << file_set
      work.save
    end

    it { is_expected.to eq [work] }
  end

  describe '#in_work_ids' do
    subject { file_set.in_work_ids }
    let(:work) { Hydra::Works::Work.create }
    before do
      work.ordered_members << file_set
      work.save
    end

    it { is_expected.to eq [work.id] }
  end

  describe '#destroy' do
    let(:work) { Hydra::Works::Work.create }
    before do
      work.ordered_members << file_set
      work.save
    end

    it "Removes the proxy, the list_node and the FileSet" do
      expect { file_set.destroy }.to change { ActiveFedora::Aggregation::Proxy.count }.by(-1)
        .and change { work.reload.ordered_member_proxies.to_a.length }.by(-1)
    end
  end

  describe 'adding collections to file sets' do
    let(:collection) { Hydra::Works::Collection.new }
    let(:exception) { ActiveFedora::AssociationTypeMismatch }
    let(:error_regex) { /is a Collection and may not be a member of the association/ }
    context 'with ordered members' do
      it 'raises AssociationTypeMismatch with a helpful error message' do
        expect { file_set.ordered_members = [collection] }.to raise_error(exception, error_regex)
        expect { file_set.ordered_members += [collection] }.to raise_error(exception, error_regex)
        expect { file_set.ordered_members << collection }.to raise_error(exception, error_regex)
      end
    end
    context 'with unordered members' do
      it 'raises AssociationTypeMismatch with a helpful error message' do
        expect { file_set.members = [collection] }.to raise_error(exception, error_regex)
        expect { file_set.members += [collection] }.to raise_error(exception, error_regex)
        expect { file_set.members << collection }.to raise_error(exception, error_regex)
      end
    end
  end

  describe '#collection?' do
    it 'is not a collection' do
      expect(file_set.collection?).to be false
    end
  end

  context 'relationships' do
    context '#parent_works and #parent_work_ids' do
      let(:parent_work) { Hydra::Works::Work.new(id: 'parent_work') }
      let(:child_file_set1)   { described_class.new(id: 'child_file_set1') }
      let(:child_file_set2)   { described_class.new(id: 'child_file_set2') }

      context 'when parent work knows about child file sets' do
        before do
          parent_work.members = [child_file_set1, child_file_set2]
          child_file_set1.save
          child_file_set2.save
          parent_work.save
        end

        it 'gets parent work' do
          expect(child_file_set1.parent_works).to match_array [parent_work]
          expect(child_file_set1.parent_work_ids).to match_array [parent_work.id]
        end
      end

      context 'when child works know about parent works' do
        # before do
        #   # NOOP: The :member_of relationship is not defined for works.  It only uses the :members relationship.
        #   child_file_set1.member_of = [parent_work]
        #   child_file_set2.member_of = [parent_work]
        # end

        it 'gets parent work' do
          skip 'Pending implementation of the :member_of relationship for works'
          expect(child_file_set1.parent_works).to match_array [parent_work]
          expect(child_file_set1.parent_work_ids).to match_array [parent_work.id]
        end
      end
    end
  end
end
