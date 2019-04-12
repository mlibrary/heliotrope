# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sighrax do
  let(:monograph) do
    create(:public_monograph) do |m|
      m.ordered_members << file_set
      m.save!
      file_set.save!
      m
    end
  end
  let(:file_set) { create(:public_file_set) }
  let(:child) { described_class.factory(file_set.id) }
  let(:parent) { child.parent }
  let(:child_presenter) { Hyrax::FileSetPresenter.new(SolrDocument.new(file_set.to_solr), nil, nil) }
  let(:parent_presenter) { Hyrax::MonographPresenter.new(SolrDocument.new(monograph.to_solr), nil) }

  before { monograph }

  context 'child' do
    it 'is the file set' do
      expect(child).to be_a_kind_of(Sighrax::Asset)
      expect(child.noid).to eq(file_set.id)
    end

    it '#parent' do
      expect(child.parent).to be_an_instance_of(Sighrax::Monograph)
      expect(child.parent.noid).to eq(monograph.id)
    end

    it '#children' do
      expect(child.children).to be_empty
    end

    it '#title' do
      expect(child.title).not_to be_empty
      expect(child.title).to eq(child_presenter.title)
    end
  end

  context 'parent' do
    it 'is the monograph' do
      expect(parent).to be_an_instance_of(Sighrax::Monograph)
      expect(parent.noid).to eq(monograph.id)
    end

    it '#parent' do
      expect(parent.parent).to be_an_instance_of(Sighrax::NullEntity)
    end

    it '#children' do
      expect(parent.children.count).to eq(1)
      expect(parent.children[0]).to be_a_kind_of(Sighrax::Asset)
      expect(parent.children[0].noid).to eq(file_set.id)
    end

    it '#title' do
      expect(parent.title).not_to be_empty
      expect(parent.title).to eq(parent_presenter.title)
    end
  end
end
