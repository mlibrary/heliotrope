# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ModelTreeService do
  let(:model_tree_service) { described_class.new }

  context 'Mock' do
    let(:noid) { 'validnoid' }

    let(:vertex) { instance_double(ModelTreeVertex, 'vertex', data: data) }
    let(:data) { { data: {} }.to_json }
    let(:message) { "ModelTreeVertex #{noid} NOT found!" }

    describe '#get_model_tree_data' do
      subject(:rvalue) { model_tree_service.get_model_tree_data(noid, restore) }

      let(:restore) { false }

      it 'vertex not found' do
        expect { subject }.to raise_error(RuntimeError, message)
      end

      context 'vertex' do
        before { allow(ModelTreeVertex).to receive(:find_by).with(noid: noid).and_return(vertex) }

        it 'gets data' do
          expect(subject).to eq ModelTreeData.from_json(vertex.data)
        end

        context 'restore' do
          let(:restore) { true }
          let(:message) { "Couldn't find ActiveFedora::Base with 'id'=#{noid}" }

          it 'not found' do
            expect { subject }.to raise_error(ActiveFedora::ObjectNotFoundError, message)
          end

          context 'base' do
            let(:base) { instance_double(FileSet, 'base') }
            let(:base_data) { { data: { kind: 'kind' } }.to_json }

            before do
              allow(ActiveFedora::Base).to receive(:find).with(noid).and_return(base)
              allow(base).to receive(:model_metadata_json).and_return(base_data)
              allow(vertex).to receive(:data=).with(base_data)
              allow(vertex).to receive(:save!)
              allow(vertex).to receive(:data).and_return(base_data)
            end

            it 'gets base data' do
              expect(subject).to eq ModelTreeData.from_json(base_data)
              expect(vertex).to have_received(:data=).with(base_data).ordered
              expect(vertex).to have_received(:save!).ordered
              expect(vertex).to have_received(:data).ordered
            end

            context 'vertex save! error' do
              before { allow(vertex).to receive(:save!).and_raise(StandardError) }

              it { expect { subject }.to raise_error(StandardError) }
            end
          end
        end
      end
    end

    describe '#set_model_tree_data' do
      subject(:rvalue) { model_tree_service.set_model_tree_data(noid, model_tree_data) }

      let(:model_tree_data) { ModelTreeData.from_json(data) }

      it 'vertex not found' do
        expect { subject }.to raise_error(RuntimeError, message)
      end

      context 'vertex' do
        let(:message) { "Couldn't find ActiveFedora::Base with 'id'=#{noid}" }

        before { allow(ModelTreeVertex).to receive(:find_by).with(noid: noid).and_return(vertex) }

        it 'base not found' do
          expect { subject }.to raise_error(ActiveFedora::ObjectNotFoundError, message)
        end

        context 'model tree data' do
          let(:base) { instance_double(FileSet, 'base') }

          before do
            allow(ActiveFedora::Base).to receive(:find).with(noid).and_return(base)
            allow(base).to receive(:model_metadata_json=).with(data)
            allow(base).to receive(:save!)
            allow(vertex).to receive(:data=).with(data)
            allow(vertex).to receive(:save!).and_return(data)
          end

          it 'sets base and vertex data' do
            expect(subject).to eq data
            expect(base).to have_received(:model_metadata_json=).with(data).ordered
            expect(base).to have_received(:save!).ordered
            expect(vertex).to have_received(:data=).with(data).ordered
            expect(vertex).to have_received(:save!).ordered
          end

          context 'base save! error' do
            before { allow(base).to receive(:save!).and_raise(StandardError) }

            it { expect { subject }.to raise_error(StandardError) }
          end

          context 'vertex save! error' do
            before { allow(base).to receive(:save!).and_raise(StandardError) }

            it { expect { subject }.to raise_error(StandardError) }
          end

          context 'non model tree data' do
            let(:model_tree_data) { double('model_tree_data') }

            it 'sets base and vertex data' do
              expect { subject }.to raise_error(StandardError)
            end
          end
        end
      end
    end

    describe '#set_model_tree_data nil' do
      subject(:rvalue) { model_tree_service.set_model_tree_data(noid, model_tree_data) }

      let(:model_tree_data) { nil }

      it 'vertex not found' do
        expect { subject }.to raise_error(RuntimeError, message)
      end

      context 'vertex' do
        let(:message) { "Couldn't find ActiveFedora::Base with 'id'=#{noid}" }

        before { allow(ModelTreeVertex).to receive(:find_by).with(noid: noid).and_return(vertex) }

        it 'base not found' do
          expect { subject }.to raise_error(ActiveFedora::ObjectNotFoundError, message)
        end

        context 'model tree data' do
          let(:base) { instance_double(FileSet, 'base') }

          before do
            allow(ActiveFedora::Base).to receive(:find).with(noid).and_return(base)
            allow(base).to receive(:model_metadata_json=).with(nil)
            allow(base).to receive(:save!)
            allow(vertex).to receive(:data=).with(nil)
            allow(vertex).to receive(:save!).and_return(nil)
          end

          it 'sets base and vertex data' do
            expect(subject).to eq nil
            expect(base).to have_received(:model_metadata_json=).with(nil).ordered
            expect(base).to have_received(:save!).ordered
            expect(vertex).to have_received(:data=).with(nil).ordered
            expect(vertex).to have_received(:save!).ordered
          end

          context 'base save! error' do
            before { allow(base).to receive(:save!).and_raise(StandardError) }

            it { expect { subject }.to raise_error(StandardError) }
          end

          context 'vertex save! error' do
            before { allow(base).to receive(:save!).and_raise(StandardError) }

            it { expect { subject }.to raise_error(StandardError) }
          end
        end
      end
    end

    describe '#unlink' do
      subject(:rvalue) { model_tree_service.unlink(noid) }

      before do
        allow(model_tree_service).to receive(:unlink_parent).with(noid)
        allow(model_tree_service).to receive(:unlink_children).with(noid)
      end

      it 'unlinks its parent and children' do
        expect(rvalue).to be true
        expect(model_tree_service).to have_received(:unlink_parent).with(noid)
        expect(model_tree_service).to have_received(:unlink_children).with(noid)
      end
    end
  end

  context 'Instance' do
    let(:work) do
      create(:public_monograph) do |m|
        m.ordered_members << asset_1
        m.ordered_members << asset_2
        m.ordered_members << asset_3
        m.save!
        # Save assets to force reindexing!!!
        asset_1.save!
        asset_2.save!
        asset_3.save!
        m
      end
    end
    let(:asset_1) { create(:public_file_set) }
    let(:asset_2) { create(:public_file_set) }
    let(:asset_3) { create(:public_file_set) }

    let(:work_noid) { work.id }
    let(:parent_noid) { asset_1.id }
    let(:child_noid) { asset_2.id }
    let(:other_noid) { asset_3.id }

    before { work }

    describe '#link' do
      subject(:rvalue) { model_tree_service.link(parent_noid, child_noid) }

      it 'creates vertices and edge' do
        expect { subject }
          .to change(ModelTreeVertex, :count).by(2)
          .and change(ModelTreeEdge, :count).by(1)
        expect(rvalue).to be true
        expect(ModelTreeEdge.find_by(parent_noid: parent_noid, child_noid: child_noid).present?).to be true
        expect(ModelTreeVertex.find_by(noid: parent_noid).present?).to be true
        expect(ModelTreeVertex.find_by(noid: child_noid).present?).to be true
      end

      it 'does nothing if the link exist' do
        expect(model_tree_service.link(parent_noid, child_noid)).to be true
        expect { subject }
          .to change(ModelTreeVertex, :count).by(0)
          .and change(ModelTreeEdge, :count).by(0)
        expect(rvalue).to be true
      end

      it 'does nothing if the child already has a parent' do
        expect(model_tree_service.link(other_noid, child_noid)).to be true
        expect { subject }
          .to change(ModelTreeVertex, :count).by(0)
          .and change(ModelTreeEdge, :count).by(0)
        expect(rvalue).to be false
      end
    end



    describe '#unlink_parent' do
      subject(:rvalue) { model_tree_service.unlink_parent(child_noid) }

      it 'does nothing if the edge does not exist' do
        expect { subject }
          .to change(ModelTreeVertex, :count).by(0)
          .and change(ModelTreeEdge, :count).by(0)
        expect(rvalue).to be true
      end

      context 'edge exist' do
        before { model_tree_service.link(parent_noid, child_noid) }

        it 'does nothing if the node is not a child' do
          expect { model_tree_service.unlink_parent(parent_noid) }
            .to change(ModelTreeVertex, :count).by(0)
            .and change(ModelTreeEdge, :count).by(0)
          expect(rvalue).to be true
        end

        it 'destroys vertices and edge' do
          expect { subject }
            .to change(ModelTreeVertex, :count).by(-2)
            .and change(ModelTreeEdge, :count).by(-1)
          expect(rvalue).to be true
        end

        context 'parent has other child' do
          before { model_tree_service.link(parent_noid, other_noid) }

          it 'destroys child vertex and edge' do
            expect { subject }
              .to change(ModelTreeVertex, :count).by(-1)
              .and change(ModelTreeEdge, :count).by(-1)
            expect(rvalue).to be true
            expect(ModelTreeVertex.find_by(noid: child_noid)).to be nil
          end
        end

        context 'child has child' do
          before { model_tree_service.link(child_noid, other_noid) }

          it 'destroys parent vertex and edge' do
            expect { subject }
              .to change(ModelTreeVertex, :count).by(-1)
              .and change(ModelTreeEdge, :count).by(-1)
            expect(rvalue).to be true
            expect(ModelTreeVertex.find_by(noid: parent_noid)).to be nil
          end
        end
      end
    end

    describe '#unlink_children' do
      subject(:rvalue) { model_tree_service.unlink_children(parent_noid) }

      it 'does nothing if the edge does not exist' do
        expect { subject }
          .to change(ModelTreeVertex, :count).by(0)
          .and change(ModelTreeEdge, :count).by(0)
        expect(rvalue).to be true
      end

      context 'parent has child' do
        before do
          model_tree_service.link(parent_noid, child_noid)
          allow(model_tree_service).to receive(:unlink_parent).with(child_noid).and_call_original
        end

        it 'calls unlink parent with child' do
          expect { subject }
            .to change(ModelTreeVertex, :count).by(-2)
            .and change(ModelTreeEdge, :count).by(-1)
          expect(rvalue).to be true
          expect(model_tree_service).to have_received(:unlink_parent).with(child_noid)
        end

        context 'parent has other child' do
          before do
            model_tree_service.link(parent_noid, other_noid)
            allow(model_tree_service).to receive(:unlink_parent).with(other_noid).and_call_original
          end

          it 'calls unlink parent with each child' do
            expect { subject }
              .to change(ModelTreeVertex, :count).by(-3)
              .and change(ModelTreeEdge, :count).by(-2)
            expect(rvalue).to be true
            expect(model_tree_service).to have_received(:unlink_parent).with(child_noid)
            expect(model_tree_service).to have_received(:unlink_parent).with(other_noid)
          end
        end
      end
    end

    context 'select_options' do
      context 'work' do
        describe '#select_parent_options' do
          subject { model_tree_service.select_parent_options(work_noid) }

          it { is_expected.to be_empty }
        end

        describe '#select_child_options' do
          subject { model_tree_service.select_child_options(work_noid) }

          it { is_expected.to contain_exactly(parent_noid, child_noid, other_noid) }

          context 'has child' do
            before {  model_tree_service.link(work_noid, child_noid) }

            it { is_expected.to contain_exactly(parent_noid, other_noid) }
          end
        end
      end

      context 'asset' do
        describe '#select_parent_options' do
          subject { model_tree_service.select_parent_options(child_noid) }

          it { is_expected.to contain_exactly(work_noid, parent_noid, other_noid) }

          context 'has parent' do
            before { model_tree_service.link(parent_noid, child_noid) }

            it { is_expected.to be_empty }
          end
        end

        describe '#select_child_options' do
          subject { model_tree_service.select_child_options(parent_noid) }

          it { is_expected.to contain_exactly(child_noid, other_noid) }

          context 'has child' do
            before { model_tree_service.link(parent_noid, child_noid) }

            it { is_expected.to contain_exactly(other_noid) }

            context 'other has parent' do
              before { model_tree_service.link(work_noid, other_noid) }

              it { is_expected.to be_empty }
            end
          end
        end
      end
    end
  end
end
