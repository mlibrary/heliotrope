require 'spec_helper'

describe Hydra::Works::Collection do
  let(:collection) { described_class.new }
  let(:collection1) { described_class.new }
  let(:work1) { Hydra::Works::Work.new }

  describe '#collections' do
    it 'returns empty array when only works are aggregated' do
      collection.ordered_members << work1
      expect(collection.collections).to eq []
    end

    context 'with other collections & works' do
      let(:collection2) { described_class.new }
      before do
        collection.ordered_members << collection1
        collection.ordered_members << collection2
        collection.ordered_members << work1
      end

      it 'returns only collections' do
        expect(collection.ordered_collections).to eq [collection1, collection2]
      end
    end
  end

  describe '#works' do
    subject { collection.works }
    context "when only collections are aggregated" do
      it 'returns empty array when only collections are aggregated' do
        collection.ordered_members << collection1
        expect(subject).to eq []
      end
    end

    context 'with collections and works' do
      let(:work2) { Hydra::Works::Work.new }
      before do
        collection.ordered_members << collection1
        collection.ordered_members << work1
        collection.ordered_members << work2
      end

      it 'returns only works' do
        expect(subject).to eq [work1, work2]
      end
    end
  end

  describe '#ordered_works' do
    subject { collection.ordered_works }
    context "when only collections are aggregated" do
      it 'returns empty array when only collections are aggregated' do
        collection.ordered_members << collection1
        expect(subject).to eq []
      end
    end

    context 'with collections and works' do
      let(:work2) { Hydra::Works::Work.new }
      before do
        collection.ordered_members << collection1
        collection.ordered_members << work1
        collection.ordered_members << work2
      end

      it 'returns only works' do
        expect(subject).to eq [work1, work2]
      end

      context "after deleting a member" do
        before do
          collection.save
          work1.destroy
          collection.reload
        end
        it { is_expected.to eq [work2] }
      end
    end
  end

  describe "#ordered_work_ids" do
    subject { collection.ordered_work_ids }
    it "returns IDs of ordered works" do
      collection.ordered_members << work1
      expect(subject).to eq [work1.id]
    end
  end

  describe "#work_ids" do
    subject { collection.work_ids }
    it "returns IDs of works" do
      collection.members = [work1]
      expect(subject).to eq [work1.id]
    end
  end

  describe '#related_objects' do
    subject { collection.related_objects }
    let(:object) { Hydra::PCDM::Object.new }
    let(:collection) { described_class.new }

    before do
      collection.related_objects = [object]
    end

    it { is_expected.to eq [object] }
  end

  describe "#in_collections" do
    before do
      collection1.ordered_members << collection
      collection1.save
    end

    subject { collection.in_collections }
    it { is_expected.to eq [collection1] }
  end

  describe 'member_of_collections' do
    let(:collection1) { described_class.create }
    before do
      collection.member_of_collections = [collection1]
    end

    it 'is a member of the collection' do
      expect(collection.member_of_collections).to eq [collection1]
      expect(collection.member_of_collection_ids).to eq [collection1.id]
    end
  end

  describe 'adding file_sets to collections' do
    let(:file_set) { Hydra::Works::FileSet.new }
    let(:exception) { ActiveFedora::AssociationTypeMismatch }
    context 'with ordered members' do
      it 'raises AssociationTypeMismatch' do
        expect { collection.ordered_members = [file_set] }.to raise_error(exception)
        expect { collection.ordered_members += [file_set] }.to raise_error(exception)
        expect { collection.ordered_members << file_set }.to raise_error(exception)
      end
    end
    context 'with unordered members' do
      it 'raises AssociationTypeMismatch' do
        expect { collection.members = [file_set] }.to raise_error(exception)
        expect { collection.members += [file_set] }.to raise_error(exception)
        expect { collection.members << file_set }.to raise_error(exception)
      end
    end
  end

  context 'relationships' do
    context '#parent_collections and #parent_collection_ids' do
      let(:parent_col1) { described_class.new(id: 'parent_col1') }
      let(:parent_col2) { described_class.new(id: 'parent_col2') }
      let(:collection) { described_class.new(id: 'collection') }

      context 'when parents collection knows about child collections' do
        before do
          parent_col1.members = [collection]
          parent_col2.members = [collection]
          collection.save
          parent_col1.save
          parent_col2.save
        end

        it 'gets both parent collections' do
          expect(collection.parent_collections).to match_array [parent_col1, parent_col2]
          expect(collection.parent_collection_ids).to match_array [parent_col1.id, parent_col2.id]
        end
      end

      context 'when child collection knows about parent collections' do
        before do
          collection.member_of_collections = [parent_col1, parent_col2]
        end

        it 'gets both parent collections' do
          expect(collection.parent_collections).to match_array [parent_col1, parent_col2]
          expect(collection.parent_collection_ids).to match_array [parent_col1.id, parent_col2.id]
        end
      end

      context 'when some children know about parent and some parents know about child' do
        before do
          parent_col1.members = [collection]
          collection.member_of_collections = [parent_col2]
          collection.save
          parent_col1.save
        end

        it 'gets both parent collections' do
          expect(collection.parent_collections).to match_array [parent_col1, parent_col2]
          expect(collection.parent_collection_ids).to match_array [parent_col1.id, parent_col2.id]
        end
      end
    end

    context '#child_collections and #child_collection_ids' do
      let(:child_col1) { described_class.new(id: 'child_col1') }
      let(:child_col2) { described_class.new(id: 'child_col2') }
      let(:child_work) { Hydra::Works::Work.new(id: 'child_work') }
      let(:collection) { described_class.new(id: 'collection') }

      context 'when child collections knows about parent collections' do
        before do
          child_col1.member_of_collections = [collection]
          child_col2.member_of_collections = [collection]
          child_work.member_of_collections = [collection]
          child_col1.save
          child_col2.save
          child_work.save
          collection.save
        end

        it 'gets both child collections' do
          expect(collection.child_collections).to match_array [child_col1, child_col2]
          expect(collection.child_collection_ids).to match_array [child_col1.id, child_col2.id]
        end
      end

      context 'when parent collection knows about child collections' do
        before do
          collection.members = [child_col1, child_col2, child_work]
        end

        it 'gets both child collections' do
          expect(collection.child_collections).to match_array [child_col1, child_col2]
          expect(collection.child_collection_ids).to match_array [child_col1.id, child_col2.id]
        end
      end

      context 'when some children know about parent and some parents know about children' do
        before do
          collection.members = [child_col1]
          child_col2.member_of_collections = [collection]
          child_work.member_of_collections = [collection]
          child_col2.save
          child_work.save
          collection.save
        end

        it 'gets both child collections' do
          expect(collection.child_collections).to match_array [child_col1, child_col2]
          expect(collection.child_collection_ids).to match_array [child_col1.id, child_col2.id]
        end
      end
    end

    context '#child_works and #child_work_ids' do
      let(:work1) { Hydra::Works::Work.new(id: 'work1') }
      let(:work2) { Hydra::Works::Work.new(id: 'work2') }
      let(:child_collection) { described_class.new(id: 'child_collection') }
      let(:collection) { described_class.new(id: 'collection') }

      context 'when child works knows about parent collections' do
        before do
          work1.member_of_collections = [collection]
          work2.member_of_collections = [collection]
          child_collection.member_of_collections = [collection]
          work1.save
          work2.save
          child_collection.save
          collection.save
        end

        it 'gets both child works' do
          expect(collection.child_works).to match_array [work1, work2]
          expect(collection.child_work_ids).to match_array [work1.id, work2.id]
        end
      end

      context 'when parent collection knows about child works' do
        before do
          collection.members = [work1, work2, child_collection]
        end

        it 'gets both child works' do
          expect(collection.child_works).to match_array [work1, work2]
          expect(collection.child_work_ids).to match_array [work1.id, work2.id]
        end
      end

      context 'when some children know about parent and some parents know about children' do
        before do
          collection.members = [work1]
          work2.member_of_collections = [collection]
          child_collection.member_of_collections = [collection]
          work2.save
          child_collection.save
          collection.save
        end

        it 'gets both child works' do
          expect(collection.child_works).to match_array [work1, work2]
          expect(collection.child_work_ids).to match_array [work1.id, work2.id]
        end
      end
    end
  end
end
