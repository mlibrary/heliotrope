require 'spec_helper'

describe Hydra::PCDM::Collection do
  let(:collection1) { described_class.new }
  let(:collection2) { described_class.new }
  let(:collection3) { described_class.new }
  let(:collection4) { described_class.new }

  let(:object1) { Hydra::PCDM::Object.new }
  let(:object2) { Hydra::PCDM::Object.new }
  let(:object3) { Hydra::PCDM::Object.new }

  describe '#collections' do
    it 'returns non-ordered collections' do
      collection1.members += [collection2, collection3]
      collection1.ordered_members << collection4

      expect(collection1.collections).to match_array [collection2, collection3, collection4]
      expect(collection1.ordered_collections).to eq [collection4]
    end
  end

  describe '#collection_ids' do
    it 'returns IDs of non-ordered collections' do
      collection1.members += [collection2, collection3]
      collection1.ordered_members << collection4

      expect(collection1.collection_ids).to match_array [collection2.id, collection3.id, collection4.id]
    end
  end

  describe '#objects' do
    it 'returns non-ordered objects' do
      collection1.members += [object1, object2]
      collection1.ordered_members << object3

      expect(collection1.objects).to match_array [object1, object2, object3]
      expect(collection1.ordered_objects).to eq [object3]
    end
  end

  describe '#object_ids' do
    it 'returns IDs of non-ordered objects' do
      collection1.members += [object1, object2]
      collection1.ordered_members << object3

      expect(collection1.object_ids).to match_array [object1.id, object2.id, object3.id]
    end
  end

  describe 'adding collections' do
    describe 'with acceptable inputs' do
      subject { described_class.new }
      it 'adds an object to collection with collections and objects' do
        subject.ordered_members << collection1
        subject.ordered_members << collection2
        subject.ordered_members << object1
        subject.ordered_members << object2
        subject.ordered_members << collection3
        expect(subject.ordered_members).to eq [collection1, collection2, object1, object2, collection3]
        expect(subject.ordered_collections).to eq [collection1, collection2, collection3]
        expect(subject.ordered_objects).to eq [object1, object2]
      end
    end

    describe '#in_collection_ids' do
      it 'returns the IDs of the parent' do
        subject.ordered_members << object1
        subject.ordered_members << collection1
        subject.save
        expect(object1.in_collection_ids).to eq [subject.id]
        expect(collection1.in_collection_ids).to eq [subject.id]
      end
    end

    describe 'aggregates collections that implement Hydra::PCDM' do
      before do
        class Kollection < ActiveFedora::Base
          include Hydra::PCDM::CollectionBehavior
        end
      end
      after { Object.send(:remove_const, :Kollection) }
      let(:kollection1) { Kollection.new }

      it 'accepts implementing collection as a child' do
        subject.ordered_members << kollection1
        expect(subject.ordered_collections).to eq [kollection1]
      end

      it 'accepts implementing collection as a parent' do
        kollection1.ordered_members << collection1
        expect(kollection1.ordered_collections).to eq [collection1]
      end
    end

    describe 'aggregates collections that extend Hydra::PCDM' do
      before do
        class Cullection < Hydra::PCDM::Collection
        end
      end
      after { Object.send(:remove_const, :Cullection) }
      let(:cullection1) { Cullection.new }

      it 'accepts extending collection as a child' do
        subject.ordered_members << cullection1
        expect(subject.ordered_collections).to eq [cullection1]
      end

      it 'accepts extending collection as a parent' do
        cullection1.ordered_members << collection1
        expect(cullection1.ordered_collections).to eq [collection1]
      end
    end

    describe 'with unacceptable input types' do
      before(:all) do
        @object101       = Hydra::PCDM::Object.new
        @file101         = Hydra::PCDM::File.new
        @non_pcdm_object = "I'm not a PCDM object"
        @af_base_object  = ActiveFedora::Base.new
      end

      context 'that are unacceptable child collections' do
        let(:error_type1)    { ActiveFedora::AssociationTypeMismatch }
        let(:error_message1) { /ActiveFedora::Base\(#\d+\) expected, got String\(#[\d]+\)/ }
        let(:error_type2)    { ActiveFedora::AssociationTypeMismatch }
        let(:error_message2) { /(<ActiveFedora::Base:[\d\s\w]{16}>|\s*) is not a PCDM object or collection./ }
        let(:error_type3)    { ActiveFedora::AssociationTypeMismatch }
        let(:error_message3) { /ActiveFedora::Base\(#\d+\) expected, got Hydra::PCDM::File\(#[\d]+\)/ }

        it 'raises an error when trying to aggregate Hydra::PCDM::Files in members aggregation' do
          expect { collection1.ordered_members << @file101 }.to raise_error(error_type3, error_message3)
        end

        it 'raises an error when trying to aggregate non-PCDM objects in members aggregation' do
          expect { collection1.ordered_members << @non_pcdm_object }.to raise_error(error_type1, error_message1)
        end

        it 'raises an error when trying to aggregate AF::Base objects in members aggregation' do
          expect { collection1.ordered_members << @af_base_object }.to raise_error(error_type2, error_message2)
        end
      end
    end

    describe 'adding collections that are ancestors' do
      let(:error_type)    { ArgumentError }
      let(:error_message) { 'Hydra::PCDM::Collection with ID:  failed to pass AncestorChecker validation' }

      context 'when the source collection is the same' do
        it 'raises an error' do
          expect { subject.ordered_members << subject }.to raise_error(error_type, error_message)
        end
      end

      before do
        subject.ordered_members << collection1
      end

      it 'raises and error' do
        expect { collection1.ordered_members << subject }.to raise_error(error_type, error_message)
      end

      context 'with more ancestors' do
        before do
          collection1.ordered_members << collection2
        end

        it 'raises an error' do
          expect { collection2.ordered_members << subject }.to raise_error(error_type, error_message)
        end

        context 'with a more complicated example' do
          before do
            collection2.ordered_members << collection3
          end

          it 'raises errors' do
            expect { collection3.ordered_members << subject }.to raise_error(error_type, error_message)
            expect { collection3.ordered_members << collection1 }.to raise_error(error_type, error_message)
          end
        end
      end
    end
  end

  describe 'removing collections' do
    subject { described_class.new }

    context 'when it is the only collection' do
      before do
        subject.ordered_members << collection1
        expect(subject.ordered_collections).to eq [collection1]
      end

      it 'removes collection while changes are in memory' do
        subject.ordered_member_proxies.delete_at(0)
        expect(subject.ordered_collections).to eq []
      end

      it 'removes collection only when objects and all changes are in memory' do
        subject.ordered_members << object1
        subject.ordered_members << object2
        subject.ordered_member_proxies.delete_at(0)
        expect(subject.ordered_collections).to eq []
        expect(subject.ordered_objects).to eq [object1, object2]
      end
    end

    context 'when multiple collections' do
      before do
        subject.ordered_members << collection1
        subject.ordered_members << collection2
        subject.ordered_members << collection3
        expect(subject.ordered_collections).to eq [collection1, collection2, collection3]
      end

      it 'removes first collection when changes are in memory' do
        subject.ordered_member_proxies.delete_at(0)
        expect(subject.ordered_collections).to eq [collection2, collection3]
      end

      it 'removes last collection when changes are in memory' do
        subject.ordered_member_proxies.delete_at(2)
        expect(subject.ordered_collections).to eq [collection1, collection2]
      end

      it 'removes middle collection when changes are in memory' do
        subject.ordered_member_proxies.delete_at(1)
        expect(subject.ordered_collections).to eq [collection1, collection3]
      end

      it 'removes middle collection when changes are saved' do
        expect(subject.ordered_collections).to eq [collection1, collection2, collection3]
        subject.save
        subject.ordered_member_proxies.delete_at(1)
        expect(subject.ordered_collections).to eq [collection1, collection3]
      end
    end
    context 'when collection is missing' do
      it 'and 0 sub-collections should return empty array' do
        expect(subject.members.delete(collection1)).to eq []
      end

      it 'and multiple sub-collections should return empty array when changes are in memory' do
        subject.ordered_members << collection1
        subject.ordered_members << collection3
        expect(subject.members.delete(collection2)).to eq []
      end

      it 'returns empty array when changes are saved' do
        subject.ordered_members << collection1
        subject.ordered_members << collection3
        subject.save
        expect(subject.members.delete(collection2)).to eq []
      end
    end
  end

  describe 'adding objects' do
    context 'with acceptable inputs' do
      it 'adds objects, sub-collections, and repeating collections' do
        subject.ordered_members << object1      # first add
        subject.ordered_members << object2      # second add to same collection
        subject.ordered_members << object1      # repeat an object
        expect(subject.ordered_members).to eq [object1, object2, object1]
      end

      context 'with collections and objects' do
        it 'adds an object to collection with collections and objects' do
          subject.ordered_members << object1
          subject.ordered_members << collection1
          subject.ordered_members << collection2
          subject.ordered_members << object2
          expect(subject.ordered_objects).to eq [object1, object2]
        end
      end

      describe 'aggregates objects that implement Hydra::PCDM' do
        before do
          class Ahbject < ActiveFedora::Base
            include Hydra::PCDM::ObjectBehavior
          end
        end
        after { Object.send(:remove_const, :Ahbject) }
        let(:ahbject1) { Ahbject.new }

        it 'accepts implementing object as a child' do
          subject.ordered_members << ahbject1
          expect(subject.ordered_objects).to eq [ahbject1]
        end
      end

      describe 'aggregates objects that extend Hydra::PCDM' do
        before do
          class Awbject < Hydra::PCDM::Object
          end
        end
        after { Object.send(:remove_const, :Awbject) }
        let(:awbject1) { Awbject.new }

        it 'accepts extending object as a child' do
          subject.ordered_members << awbject1
          expect(subject.ordered_objects).to eq [awbject1]
        end
      end
    end
  end

  describe 'add related objects' do
    context 'with acceptable collections' do
      it 'adds objects to the related object set' do
        collection1.related_objects << object1      # first add
        collection1.related_objects << object2      # second add to same collection
        collection1.save
        related_objects = collection1.reload.related_objects
        expect(related_objects).to match_array [object1, object2]
      end

      it 'is empty when no related objects' do
        expect(collection1.related_objects).to eq []
      end

      it 'does not repeat objects in the related object set' do
        skip 'pending resolution of ActiveFedora issue #853' do
          collection1.related_objects << object1      # first add
          collection1.related_objects << object2      # second add to same collection
          collection1.related_objects << object1      # repeat an object replaces the object
          related_objects = collection1.related_objects
          expect(related_objects).to match_array [object1, object2]
        end
      end
    end
    context 'with unacceptable inputs' do
      before(:all) do
        @file101         = Hydra::PCDM::File.new
        @non_pcdm_object = "I'm not a PCDM object"
        @af_base_object  = ActiveFedora::Base.new
      end

      context 'with unacceptable related objects' do
        it 'raises an error when trying to aggregate Hydra::PCDM::Collection in objects aggregation' do
          expect { collection2.related_objects << collection1 }.to raise_error(ActiveFedora::AssociationTypeMismatch, /Hydra::PCDM::Collection:.* is not a PCDM object/)
        end

        it 'raises an error when trying to aggregate Hydra::PCDM::Files in objects aggregation' do
          expect { collection2.related_objects << @file101 }.to raise_error(ActiveFedora::AssociationTypeMismatch, /ActiveFedora::Base\(#\d+\) expected, got Hydra::PCDM::File\(#\d+\)/)
        end

        it 'raises an error when trying to aggregate non-PCDM objects in objects aggregation' do
          expect { collection2.related_objects << @non_pcdm_object }.to raise_error(ActiveFedora::AssociationTypeMismatch, /ActiveFedora::Base\(#\d+\) expected, got String\(#\d+\)/)
        end

        it 'raises an error when trying to aggregate AF::Base objects in objects aggregation' do
          expect { collection2.related_objects << @af_base_object }.to raise_error(ActiveFedora::AssociationTypeMismatch, /ActiveFedora::Base:.*> is not a PCDM object/)
        end
      end

      context 'with unacceptable parent object' do
        it 'raises an error when trying to accept Hydra::PCDM::Files as parent object' do
          expect { @file1.related_objects << object1 }.to raise_error(NoMethodError)
        end

        it 'raises an error when trying to accept non-PCDM objects as parent object' do
          expect { @non_pcdm_object.related_objects << object1 }.to raise_error(NoMethodError)
        end

        it 'raises an error when trying to accept AF::Base objects as parent object' do
          expect { @af_base_object.related_objects << object1 }.to raise_error(NoMethodError)
        end

        it 'Hydra::PCDM::File should NOT have related files' do
          expect { @file1.related_objects }.to raise_error(NoMethodError)
        end

        it 'Non-PCDM objects should should NOT have related objects' do
          expect { @non_pcdm_object.related_objects }.to raise_error(NoMethodError)
        end

        it 'AF::Base should NOT have related_objects' do
          expect { @af_base_object.related_objects }.to raise_error(NoMethodError)
        end
      end
    end
  end

  describe 'remove related objects' do
    context 'when it is the only related object' do
      let(:object3) { Hydra::PCDM::Object.new }

      before do
        subject.related_objects << object1
        expect(subject.related_objects).to eq [object1]
      end

      it 'removes related object while changes are in memory' do
        expect(subject.related_objects.delete(object1)).to eq [object1]
        expect(subject.related_objects).to eq []
      end

      it 'removes related object only when objects & collections and all changes are in memory' do
        subject.ordered_members << collection1
        subject.ordered_members << collection2
        subject.ordered_members << object3
        subject.ordered_members << object2
        expect(subject.related_objects.delete(object1)).to eq [object1]
        expect(subject.related_objects).to eq []
        expect(subject.ordered_collections).to eq [collection1, collection2]
        expect(subject.ordered_objects).to eq [object3, object2]
      end
    end

    context 'when multiple related objects' do
      let(:object3) { Hydra::PCDM::Object.new }

      before do
        subject.related_objects << object1
        subject.related_objects << object2
        subject.related_objects << object3
        expect(subject.related_objects).to match_array [object1, object2, object3]
      end

      it 'removes first related object when changes are in memory' do
        expect(subject.related_objects.delete(object1)).to eq [object1]
        expect(subject.related_objects).to match_array [object2, object3]
      end

      it 'removes last related object when changes are in memory' do
        expect(subject.related_objects.delete(object3)).to eq [object3]
        expect(subject.related_objects).to match_array [object1, object2]
      end

      it 'removes middle related object when changes are in memory' do
        expect(subject.related_objects.delete(object2)).to eq [object2]
        expect(subject.related_objects).to match_array [object1, object3]
      end

      it 'removes middle related object when changes are saved' do
        expect(subject.related_objects).to contain_exactly object1, object2, object3
        expect(subject.related_objects.delete(object2)).to eq [object2]
        subject.save
        expect(subject.reload.related_objects).to contain_exactly object1, object3
      end
    end

    context 'when related object is missing' do
      let(:object3) { Hydra::PCDM::Object.new }

      it 'returns empty array when 0 related objects and 0 collections and objects' do
        expect(subject.related_objects.delete(object1)).to eq []
      end

      it 'returns empty array when 0 related objects, but has collections and objects and changes in memory' do
        subject.ordered_members << collection1
        subject.ordered_members << collection2
        subject.ordered_members << object1
        subject.ordered_members << object2
        expect(subject.related_objects.delete(object1)).to eq []
      end

      it 'returns empty array when other related objects and changes are in memory' do
        subject.related_objects << object1
        subject.related_objects << object3
        expect(subject.related_objects.delete(object2)).to eq []
      end

      it 'returns empty array when changes are saved' do
        subject.related_objects << object1
        subject.related_objects << object3
        subject.save
        expect(subject.reload.related_objects.delete(object2)).to eq []
      end
    end
  end

  context 'with unacceptable inputs' do
    before(:all) do
      @file101         = Hydra::PCDM::File.new
      @non_pcdm_object = "I'm not a PCDM object"
      @af_base_object  = ActiveFedora::Base.new
    end

    context 'that are unacceptable parent collections' do
      it 'raises an error when trying to accept Hydra::PCDM::Files as parent collection' do
        expect { @file101.related_objects.delete object1 }.to raise_error(NoMethodError)
      end

      it 'raises an error when trying to accept non-PCDM objects as parent collection' do
        expect { @non_pcdm_object.related_objects.delete object1 }.to raise_error(NoMethodError)
      end

      it 'raises an error when trying to accept AF::Base objects as parent collection' do
        expect { @af_base_object.related_objects.delete object1 }.to raise_error(NoMethodError)
      end
    end
  end

  describe '#ordered_collection_ids' do
    subject      { object.ordered_collection_ids }
    let(:child1) { described_class.new(id: '1') }
    let(:child2) { described_class.new(id: '2') }
    let(:object) { described_class.new }

    before { object.ordered_members = [child1, child2] }

    it { is_expected.to eq %w[1 2] }
  end

  describe 'collections and objects' do
    subject { described_class.new }

    it 'returns empty array when no members' do
      expect(subject.ordered_collections).to eq []
      expect(subject.ordered_objects).to eq []
    end

    it 'collections should return empty array when only objects are aggregated' do
      subject.ordered_members << object1
      subject.ordered_members << object2
      expect(subject.ordered_collections).to eq []
    end

    it 'objects should return empty array when only collections are aggregated' do
      subject.ordered_members << collection1
      subject.ordered_members << collection2
      expect(subject.ordered_objects).to eq []
    end

    context 'should only contain members of the correct type' do
      it 'returns only collections' do
        subject.ordered_members << collection1
        subject.ordered_members << collection2
        subject.ordered_members << object1
        subject.ordered_members << object2
        expect(subject.ordered_collections).to eq [collection1, collection2]
        expect(subject.ordered_objects).to eq [object1, object2]
        expect(subject.ordered_members).to eq [collection1, collection2, object1, object2]
      end
    end
  end

  context 'when aggregated by other objects' do
    before do
      # Using before(:all) and instance variable because regular :let syntax had a significant impact on performance
      # All of the tests in this context are describing idempotent behavior, so isolation between examples isn't necessary.
      @collection1 = described_class.new
      @collection2 = described_class.new
      @collection =  described_class.new
      @collection1.members << @collection
      @collection2.members << @collection
      @collection.save
      @collection1.save!
      @collection2.save!
    end

    describe 'member_of' do
      subject { @collection.member_of }
      it 'finds all nodes that aggregate the object with hasMember' do
        expect(subject.to_a).to include(@collection1, @collection2)
        expect(subject.count).to eq 2
      end
    end

    describe 'in_collections' do
      subject { @collection.in_collections }
      it 'finds collections that aggregate the object with hasMember' do
        expect(subject).to include(@collection1, @collection2)
        expect(subject.count).to eq 2
      end
    end
  end

  describe 'membership in collections' do
    subject do
      collection = described_class.new
      collection.member_of_collections = [collection1, collection2]
      collection
    end

    let(:collection1) { described_class.create }
    let(:collection2) { described_class.create }

    describe '#member_of_collections' do
      it 'contains collections the object is a member of' do
        expect(subject.member_of_collections).to match_array [collection1, collection2]
      end
    end

    describe '#member_of_collection_ids' do
      it 'contains the ids of collections the object is a member of' do
        expect(subject.member_of_collection_ids).to match_array [collection1.id, collection2.id]
      end
    end
  end

  describe '.indexer' do
    after do
      Object.send(:remove_const, :Foo)
    end

    context 'without overriding' do
      before do
        class Foo < ActiveFedora::Base
          include Hydra::PCDM::CollectionBehavior
        end
      end

      subject { Foo.indexer }
      it { is_expected.to eq Hydra::PCDM::CollectionIndexer }
    end

    context 'when overridden with AS::Concern' do
      before do
        module IndexingStuff
          extend ActiveSupport::Concern

          class AltIndexer; end

          module ClassMethods
            def indexer
              AltIndexer
            end
          end
        end

        class Foo < ActiveFedora::Base
          include Hydra::PCDM::CollectionBehavior
          include IndexingStuff
        end
      end

      subject { Foo.indexer }
      it { is_expected.to eq IndexingStuff::AltIndexer }
    end
  end
end
