require 'spec_helper'

describe Hydra::PCDM::Object do
  describe '#object_ids' do
    subject      { object.ordered_object_ids }
    let(:child1) { described_class.new(id: '1') }
    let(:child2) { described_class.new(id: '2') }
    let(:object) { described_class.new }

    before do
      object.ordered_members << child1
      object.ordered_members << child2
    end

    it { is_expected.to eq %w[1 2] }
  end

  describe '#ordered_member_ids' do
    it 'returns IDs of all ordered members' do
      o = described_class.new
      subject.ordered_members << o

      expect(subject.ordered_member_ids).to eq [o.id]
    end
  end

  describe '#members=, +=, <<' do
    context 'with acceptable child objects' do
      let(:object1) { described_class.new }
      let(:object2) { described_class.new }
      let(:object3) { described_class.new }
      let(:object4) { described_class.new }
      let(:object5) { described_class.new }

      it 'add objects' do
        subject.ordered_members = [object1, object2]
        subject.ordered_members << object3
        subject.ordered_members += [object4, object5]
        expect(subject.ordered_members).to eq [object1, object2, object3, object4, object5]
      end

      it 'allow sub-objects' do
        subject.ordered_members = [object1, object2]
        object1.ordered_members = [object3]
        expect(subject.ordered_members).to eq [object1, object2]
        expect(object1.ordered_members).to eq [object3]
      end

      it 'allow repeating objects' do
        subject.ordered_members = [object1, object2, object1]
        expect(subject.ordered_members).to eq [object1, object2, object1]
      end

      describe 'adding objects that are ancestors' do
        let(:error_type)    { ArgumentError }
        let(:error_message) { 'Hydra::PCDM::Object with ID:  failed to pass AncestorChecker validation' }

        context 'when the source object is the same' do
          it 'raises an error' do
            expect { object1.ordered_members = [object1] }.to raise_error(error_type, error_message)
            expect { object1.ordered_members += [object1] }.to raise_error(error_type, error_message)
            expect { object1.ordered_members << [object1] }.to raise_error(error_type, error_message)
          end
        end

        before { object1.ordered_members = [object2] }

        it 'raises an error' do
          expect { object2.ordered_members += [object1] }.to raise_error(error_type, error_message)
          expect { object2.ordered_members << [object1] }.to raise_error(error_type, error_message)
          expect { object2.ordered_members = [object1] }.to raise_error(error_type, error_message)
        end

        context 'with more ancestors' do
          before { object2.ordered_members = [object3] }

          it 'raises an error' do
            expect { object3.ordered_members << [object1] }.to raise_error(error_type, error_message)
            expect { object3.ordered_members = [object1] }.to raise_error(error_type, error_message)
            expect { object3.ordered_members += [object1] }.to raise_error(error_type, error_message)
          end
        end

        context 'with a more complicated example' do
          before do
            object2.ordered_members = [object3]
            object3.ordered_members = [object4, object5]
          end

          it 'raises errors' do
            expect { object4.ordered_members = [object1] }.to raise_error(error_type, error_message)
            expect { object4.ordered_members += [object1] }.to raise_error(error_type, error_message)
            expect { object4.ordered_members << [object1] }.to raise_error(error_type, error_message)

            expect { object4.ordered_members = [object2] }.to raise_error(error_type, error_message)
            expect { object4.ordered_members += [object2] }.to raise_error(error_type, error_message)
            expect { object4.ordered_members << [object2] }.to raise_error(error_type, error_message)
          end
        end
      end
    end

    context 'with unacceptable child objects' do
      before(:all) do
        @collection101   = Hydra::PCDM::Collection.new
        @object101       = described_class.new
        @file101         = Hydra::PCDM::File.new
        @non_pcdm_object = "I'm not a PCDM object"
        @af_base_object  = ActiveFedora::Base.new
      end

      let(:error_type1)    { ActiveFedora::AssociationTypeMismatch }
      let(:error_message1) { /(<ActiveFedora::Base:[\d\s\w]{16}>|\s*) is not a PCDM object./ }

      let(:error_type2)    { ActiveFedora::AssociationTypeMismatch }
      let(:error_message2) { /ActiveFedora::Base\(#\d+\) expected, got NilClass\(#[\d]+\)/ }

      let(:error_type3)    { ActiveFedora::AssociationTypeMismatch }
      let(:error_message3) { /ActiveFedora::Base\(#\d+\) expected, got String\(#[\d]+\)/ }

      it 'NOT aggregate Hydra::PCDM::Collection in members aggregation' do
        expect { @object101.ordered_members = [@collection101] }.to raise_error(error_type1, error_message1)
        expect { @object101.ordered_members += [@collection101] }.to raise_error(error_type1, error_message1)
        expect { @object101.ordered_members << @collection101 }.to raise_error(error_type1, error_message1)
      end
      it 'NOT aggregate Hydra::PCDM::Files in members aggregation' do
        expect { @object101.ordered_members += [@file1] }.to raise_error(error_type2, error_message2)
        expect { @object101.ordered_members << @file1 }.to raise_error(error_type2, error_message2)
        expect { @object101.ordered_members = [@file1] }.to raise_error(error_type2, error_message2)
      end

      it 'NOT aggregate non-PCDM objects in members aggregation' do
        expect { @object101.ordered_members << @non_pcdm_object }.to raise_error(error_type3, error_message3)
        expect { @object101.ordered_members = [@non_pcdm_object] }.to raise_error(error_type3, error_message3)
        expect { @object101.ordered_members += [@non_pcdm_object] }.to raise_error(error_type3, error_message3)
      end

      it 'NOT aggregate non-PCDM AF::Base objects in members aggregation' do
        expect { @object101.ordered_members = [@af_base_object] }.to raise_error(error_type1, error_message1)
        expect { @object101.ordered_members += [@af_base_object] }.to raise_error(error_type1, error_message1)
        expect { @object101.ordered_members << @af_base_object }.to raise_error(error_type1, error_message1)
      end
    end
  end

  describe 'in_objects' do
    subject             { object.in_objects }
    let(:object)        { described_class.create }
    let(:collection)    { Hydra::PCDM::Collection.new }
    let(:parent_object) { described_class.new }

    context 'using ordered_members' do
      before do
        collection.ordered_members = [object]
        parent_object.ordered_members = [object]
        parent_object.save
        collection.save
      end

      it 'finds objects that aggregate the object' do
        expect(subject).to eq [parent_object]
      end
    end
    context 'using members' do
      before do
        collection.members = [object]
        parent_object.members = [object]
        parent_object.save
        collection.save
      end

      it 'finds objects that aggregate the object' do
        expect(subject).to eq [parent_object]
      end
    end
  end

  describe 'in_collections' do
    subject             { object.in_collections }
    let(:object)        { described_class.create }
    let(:collection1)   { Hydra::PCDM::Collection.new }
    let(:collection2)   { Hydra::PCDM::Collection.new }
    let(:parent_object) { described_class.new }

    context 'using ordered_members' do
      before do
        collection1.ordered_members = [object]
        collection2.ordered_members = [object]
        parent_object.ordered_members = [object]
        parent_object.save
        collection1.save
        collection2.save
      end

      it 'finds collections that aggregate the object' do
        expect(subject).to match_array [collection1, collection2]
        expect(subject.count).to eq 2
      end
    end
    context 'using members' do
      before do
        collection1.members = [object]
        collection2.members = [object]
        parent_object.members = [object]
        parent_object.save
        collection1.save
        collection2.save
      end

      it 'finds collections that aggregate the object' do
        expect(subject).to match_array [collection1, collection2]
        expect(subject.count).to eq 2
      end
    end
  end

  describe 'member_of' do
    subject { object.member_of }

    context 'when it is aggregated by other objects' do
      let(:object)        { described_class.create }
      let(:collection)    { Hydra::PCDM::Collection.new }
      let(:parent_object) { described_class.new }

      before do
        collection.ordered_members = [object]
        parent_object.ordered_members = [object]
        parent_object.save
        collection.save
      end

      it 'finds all nodes that aggregate the object' do
        expect(subject).to include(collection, parent_object)
      end
    end

    context 'when the object is not saved' do
      let(:object) { described_class.new }

      context 'and other objects exist in the repo' do
        before { Hydra::PCDM::Collection.create }
        it 'is empty' do
          expect(subject).to be_empty
        end
      end
    end
  end

  describe 'Related objects' do
    context 'with acceptable objects' do
      let(:object1) { described_class.new }
      let(:object2) { described_class.new }
      let(:object3) { described_class.new }
      let(:file1)   { Hydra::PCDM::File.new }

      it 'return empty array when no related object' do
        expect(subject.related_objects).to eq []
      end

      it 'add objects to the related object set' do
        subject.related_objects << object1      # first add
        subject.related_objects << object2      # second add to same object
        subject.save
        related_objects = subject.reload.related_objects
        expect(related_objects).to match_array [object1, object2]
      end

      it 'not repeat objects in the related object set' do
        skip 'pending resolution of ActiveFedora issue #853' do
          subject.related_objects << object1      # first add
          subject.related_objects << object2      # second add to same object
          subject.related_objects << object1      # repeat an object replaces the object
          related_objects = subject.related_objects
          expect(related_objects).to match_array [object1, object2]
        end
      end
    end

    context 'with unacceptable inputs' do
      before do
        @collection101   = Hydra::PCDM::Collection.new
        @object101       = described_class.new
        @file101         = Hydra::PCDM::File.new
        @non_pcdm_object = "I'm not a PCDM object"
        @af_base_object  = ActiveFedora::Base.new
      end

      context 'with unacceptable related objects' do
        let(:error_message) { 'child_related_object must be a pcdm object' }

        it 'NOT aggregate Hydra::PCDM::Collection in objects aggregation' do
          expect { @object101.related_objects << @collection101 }.to raise_error(ActiveFedora::AssociationTypeMismatch, /Hydra::PCDM::Collection:.*> is not a PCDM object./)
        end

        it 'NOT aggregate Hydra::PCDM::Files in objects aggregation' do
          expect { @object101.related_objects << @file1 }.to raise_error(ActiveFedora::AssociationTypeMismatch, /ActiveFedora::Base.* expected, got NilClass.*/)
        end

        it 'NOT aggregate non-PCDM objects in objects aggregation' do
          expect { @object101.related_objects << @non_pcdm_object }.to raise_error(ActiveFedora::AssociationTypeMismatch, /ActiveFedora::Base.* expected, got String.*/)
        end

        it 'NOT aggregate AF::Base objects in objects aggregation' do
          expect { @object101.related_objects << @af_base_object }.to raise_error(ActiveFedora::AssociationTypeMismatch, /ActiveFedora::Base:.*> is not a PCDM object./)
        end
      end

      context 'with unacceptable parent object' do
        it 'NOT accept Hydra::PCDM::Files as parent object' do
          expect { @file1.related_objects << @object101 }.to raise_error(NoMethodError)
        end

        it 'NOT accept non-PCDM objects as parent object' do
          expect { @non_pcdm_object.related_objects << @object101 }.to raise_error(NoMethodError)
        end

        it 'NOT accept AF::Base objects as parent object' do
          expect { @af_base_object.related_objects << @object101 }.to raise_error(NoMethodError)
        end

        it 'NOT access Hydra::PCDM::Files as parent object' do
          expect { @file101.related_objects }.to raise_error(NoMethodError)
        end

        it 'NOT access non-PCDM objects as parent object' do
          expect { @non_pcdm_object.related_objects }.to raise_error(NoMethodError)
        end

        it 'NOT access AF::Base objects as parent object' do
          expect { @af_base_object.related_objects }.to raise_error(NoMethodError)
        end
      end
    end
  end

  describe 'removing related objects' do
    subject { described_class.new }

    let(:object1) { described_class.new }
    let(:object2) { described_class.new }
    let(:object3) { described_class.new }
    let(:object4) { described_class.new }
    let(:object5) { described_class.new }

    let(:file1) { Hydra::PCDM::File.new }
    let(:file2) { Hydra::PCDM::File.new }

    context 'when it is the only related object' do
      before do
        subject.related_objects << object1
        expect(subject.related_objects).to eq [object1]
      end

      it 'remove related object while changes are in memory' do
        expect(subject.related_objects.delete(object1)).to eq [object1]
        expect(subject.related_objects).to eq []
      end
    end

    context 'when multiple related objects' do
      before do
        subject.related_objects << object1
        subject.related_objects << object2
        subject.related_objects << object3
        subject.related_objects << object4
        subject.related_objects << object5
        expect(subject.related_objects).to match_array [object1, object2, object3, object4, object5]
      end

      it 'remove first related object when changes are in memory' do
        expect(subject.related_objects.delete(object1)).to eq [object1]
        expect(subject.related_objects).to match_array [object2, object3, object4, object5]
      end

      it 'remove last related object when changes are in memory' do
        expect(subject.related_objects.delete(object5)).to eq [object5]
        expect(subject.related_objects).to match_array [object1, object2, object3, object4]
      end

      it 'remove middle related object when changes are in memory' do
        expect(subject.related_objects.delete(object3)).to eq [object3]
        expect(subject.related_objects).to match_array [object1, object2, object4, object5]
      end

      it 'remove middle related object when changes are saved' do
        expect(subject.related_objects).to contain_exactly object1, object2, object3, object4, object5
        expect(subject.related_objects.delete(object3)).to eq [object3]
        subject.save
        expect(subject.reload.related_objects).to contain_exactly object1, object2, object4, object5
      end
    end

    context 'when related object is missing' do
      it 'return empty array when 0 related objects and 0 objects' do
        expect(subject.related_objects.delete(object1)).to eq []
      end

      it 'return empty array when other related objects and changes are in memory' do
        subject.related_objects << object1
        subject.related_objects << object2
        subject.related_objects << object4
        subject.related_objects << object5
        expect(subject.related_objects.delete(object3)).to eq []
      end

      it 'return empty array when changes are saved' do
        subject.related_objects << object1
        subject.related_objects << object2
        subject.related_objects << object4
        subject.related_objects << object5
        subject.save
        expect(subject.reload.related_objects.delete(object3)).to eq []
      end
    end
  end

  describe '#files' do
    subject { described_class.new }

    it 'have a files relation' do
      reflection = subject.reflections[:files]
      expect(reflection.macro).to eq :directly_contains
      expect(reflection.options[:has_member_relation]).to eq Hydra::PCDM::Vocab::PCDMTerms.hasFile
      expect(reflection.options[:class_name].to_s).to eq 'Hydra::PCDM::File'
    end
  end

  describe 'filtering files' do
    let(:object) { described_class.create }

    let(:thumbnail) do
      file = object.files.build
      Hydra::PCDM::AddTypeToFile.call(file, pcdm_thumbnail_uri)
    end

    let(:file)                { object.files.build }
    let(:pcdm_thumbnail_uri)  { ::RDF::URI('http://pcdm.org/ThumbnailImage') }

    before { file }

    describe 'filter_files_by_type' do
      context 'when the object has files with that type' do
        before { thumbnail }

        it 'allows you to filter the contained files by type URI' do
          expect(object.filter_files_by_type(pcdm_thumbnail_uri)).to eq [thumbnail]
        end
        it 'only overrides the #files method when you specify :type' do
          expect(object.files).to match_array [file, thumbnail]
        end
      end

      context 'when the object does NOT have any files with that type' do
        it 'returns an empty array' do
          expect(object.filter_files_by_type(pcdm_thumbnail_uri)).to eq []
        end
      end
    end

    describe 'file_of_type' do
      context 'when the object has files with that type' do
        before { thumbnail }

        it 'returns the first file with the requested type' do
          expect(object.file_of_type(pcdm_thumbnail_uri)).to eq thumbnail
        end
      end

      context 'when the object does NOT have any files with that type' do
        it 'initializes a contained file with the requested type' do
          returned_file =  object.file_of_type(pcdm_thumbnail_uri)
          expect(object.files).to include(returned_file)
          expect(returned_file).to be_new_record
          expect(returned_file.metadata_node.get_values(:type)).to include(pcdm_thumbnail_uri)
        end
      end
    end
  end

  describe '.indexer' do
    after { Object.send(:remove_const, :Foo) }

    context 'without overriding' do
      subject { Foo.indexer }

      before do
        class Foo < ActiveFedora::Base
          include Hydra::PCDM::ObjectBehavior
        end
      end

      it { is_expected.to eq Hydra::PCDM::ObjectIndexer }
    end

    context 'when overridden with AS::Concern' do
      subject { Foo.indexer }

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
          include Hydra::PCDM::ObjectBehavior
          include IndexingStuff
        end
      end

      it { is_expected.to eq IndexingStuff::AltIndexer }
    end
  end

  describe 'membership in collections' do
    subject do
      object = described_class.new
      object.member_of_collections = [collection1, collection2]
      object.save
      object
    end

    let(:collection1) { Hydra::PCDM::Collection.create }
    let(:collection2) { Hydra::PCDM::Collection.create }

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
end
