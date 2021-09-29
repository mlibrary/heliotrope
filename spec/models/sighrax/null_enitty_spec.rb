# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sighrax::NullEntity, type: :model do
  subject { Sighrax::Entity.null_entity(noid) }

  let (:noid) { 'invalid_noid' }

  context 'when noid is blank' do
    let(:noid) { nil }

    it { is_expected                    .to be_an_instance_of(Sighrax::NullEntity) }
    it { expect(subject.noid)           .to eq 'null_noid' }
    it { expect(subject.send(:data))    .to eq({}) }
    it { expect(subject.resource_id)    .to eq 'null_noid' }
    it { expect(subject.resource_token) .to eq 'NullEntity:null_noid' }
    it { expect(subject.resource_type)  .to eq :NullEntity }
    it { expect(subject.title)          .to eq 'null_noid' }
    it { expect(subject.uri)            .to eq ActiveFedora::Base.id_to_uri('null_noid') }
    it { expect(subject.valid?)         .to be false }
  end

  context 'when noid is present' do
    it { is_expected                    .to be_an_instance_of(Sighrax::NullEntity) }
    it { expect(subject.noid)           .to be noid }
    it { expect(subject.send(:data))    .to eq({}) }
    it { expect(subject.resource_id)    .to be noid }
    it { expect(subject.resource_token) .to eq "NullEntity:#{noid}" }
    it { expect(subject.resource_type)  .to eq :NullEntity }
    it { expect(subject.title)          .to be noid }
    it { expect(subject.uri)            .to eq ActiveFedora::Base.id_to_uri(noid) }
    it { expect(subject.valid?)         .to be false }
  end

  context 'when noid is present and a derived class method' do
    it { expect(subject.allow_download?)  .to be false }
    it { expect(subject.children)         .to eq([]) }
    it { expect(subject.content)          .to eq('') }
    it { expect(subject.contributors)     .to eq([]) }
    it { expect(subject.cover)            .to eq(Sighrax::Entity.null_entity) }
    it { expect(subject.deposited?)       .to be true }
    it { expect(subject.description)      .to eq('') }
    it { expect(subject.downloadable?)    .to be false }
    it { expect(subject.ebook)            .to eq(Sighrax::Entity.null_entity) }
    it { expect(subject.epub_ebook)       .to eq(Sighrax::Entity.null_entity) }
    it { expect(subject.file_name)        .to eq('null_file.txt') }
    it { expect(subject.file_size)        .to eq 0 }
    it { expect(subject.identifier)       .to eq(HandleNet.url(noid)) }
    it { expect(subject.languages)        .to eq([]) }
    it { expect(subject.media_type)       .to eq('text/plain') }
    it { expect(subject.modified)         .to be nil }
    it { expect(subject.monograph)        .to be_an_instance_of(Sighrax::NullEntity) }
    it { expect(subject.open_access?)     .to be false }
    it { expect(subject.parent)           .to be_an_instance_of(Sighrax::NullEntity) }
    it { expect(subject.pdf_ebook)        .to eq(Sighrax::Entity.null_entity) }
    it { expect(subject.products)         .to eq([]) }
    it { expect(subject.publication_year) .to be nil }
    it { expect(subject.published)        .to be nil }
    it { expect(subject.published?)       .to be false }
    it { expect(subject.publisher)        .to be_an_instance_of(Sighrax::NullPublisher) }
    it { expect(subject.publishing_house) .to eq('') }
    it { expect(subject.restricted?)      .to be false }
    it { expect(subject.timestamp)        .to be nil }
    it { expect(subject.series)           .to eq('') }
    it { expect(subject.subjects)         .to eq([]) }
    it { expect(subject.tombstone?)       .to be false }
    it { expect(subject.tombstone_message).to be nil }
    it { expect(subject.watermarkable?)   .to be false }
  end

  context 'when compared to an instance that has a blank solr document' do
    [
      Sighrax::Entity,
      Sighrax::Model,
      Sighrax::Work,
      Sighrax::Monograph,
      Sighrax::Score,
      Sighrax::Resource,
      Sighrax::InteractiveMap,
      Sighrax::Ebook,
      Sighrax::AudiobookEbook,
      Sighrax::EpubEbook,
      Sighrax::MobiEbook,
      Sighrax::PdfEbook
    ].each do |klass|
      context klass.to_s do
        let(:instance) { klass.send(:new, noid, {}) }

        it { expect(instance).to be_an_instance_of(klass) }

        # Entity
        it { expect(subject.noid)               .to eq instance.noid }
        it { expect(subject.send(:data))        .to eq(instance.send(:data)) }
        it { expect(subject.resource_id)        .to eq instance.resource_id }
        it { expect(subject.resource_token) .not_to eq instance.resource_token }
        it { expect(subject.resource_type)  .not_to eq instance.resource_type }
        it { expect(subject.title)              .to eq instance.title }
        it { expect(subject.uri)                .to eq instance.uri }
        it { expect(subject.valid?)         .not_to eq instance.valid? }
        next if [Sighrax::Entity].include?(klass)

        # Model
        it { expect(subject.children)          .to eq instance.children }
        it { expect(subject.deposited?)        .to eq instance.deposited? }
        it { expect(subject.modified)          .to eq instance.modified }
        it { expect(subject.parent)            .to eq instance.parent }
        it { expect(subject.published?)        .to eq instance.published? }
        it { expect(subject.publisher)         .to eq instance.publisher }
        it { expect(subject.timestamp)         .to eq instance.timestamp }
        it { expect(subject.title)             .to eq instance.title }
        it { expect(subject.tombstone?)        .to eq instance.tombstone? }
        it { expect(subject.tombstone_message) .to eq instance.tombstone_message }
        next if [Sighrax::Model].include?(klass)

        # Work
        if [
          Sighrax::Work,
          Sighrax::Monograph,
          Sighrax::Score
        ].include?(klass)
          # it { expect(subject.children).to eq instance.children }
          if [Sighrax::Monograph].include?(klass)
            it { expect(subject.contributors)     .to eq instance.contributors }
            it { expect(subject.cover)            .to eq instance.cover }
            it { expect(subject.description)      .to eq instance.description }
            it { expect(subject.ebook)            .to eq instance.epub_ebook }
            it { expect(subject.epub_ebook)       .to eq instance.epub_ebook }
            it { expect(subject.identifier)       .to eq instance.identifier }
            it { expect(subject.languages)        .to eq instance.languages }
            it { expect(subject.modified)         .to eq instance.modified }
            it { expect(subject.open_access?)     .to eq instance.open_access? }
            it { expect(subject.pdf_ebook)        .to eq instance.pdf_ebook }
            it { expect(subject.products)         .to eq instance.products }
            it { expect(subject.publication_year) .to eq instance.publication_year }
            it { expect(subject.published)        .to eq instance.published }
            it { expect(subject.publishing_house) .to eq instance.publishing_house }
            it { expect(subject.restricted?)      .to eq instance.restricted? }
            it { expect(subject.series)           .to eq instance.series }
            it { expect(subject.subjects)         .to eq instance.subjects }
          end
        end

        # Resource
        if [
          Sighrax::Resource,
          Sighrax::InteractiveMap,
          Sighrax::Ebook,
          Sighrax::AudiobookEbook,
          Sighrax::EpubEbook,
          Sighrax::MobiEbook,
          Sighrax::PdfEbook
        ].include?(klass)
          it { expect(subject.allow_download?)    .to eq instance.allow_download? }
          it { expect(subject.content)            .to eq instance.content }
          it { expect(subject.downloadable?)  .not_to eq instance.downloadable? }
          it { expect(subject.file_name)          .to eq instance.file_name }
          it { expect(subject.file_size)          .to eq instance.file_size }
          it { expect(subject.media_type)         .to eq instance.media_type }
          it { expect(subject.parent)             .to eq instance.parent }

          # Electronic Book
          if [
            Sighrax::Ebook,
            Sighrax::AudiobookEbook,
            Sighrax::EpubEbook,
            Sighrax::MobiEbook,
            Sighrax::PdfEbook
          ].include?(klass)
            it { expect(subject.monograph)       .to eq instance.monograph }
            it { expect(subject.open_access?)    .to eq instance.open_access? }
            it { expect(subject.products)        .to eq instance.products }
            it { expect(subject.restricted?)     .to eq instance.restricted? }
            it { expect(subject.tombstone?)      .to eq instance.tombstone? }

            # Portable Document Format is watermark-able!
            if [Sighrax::PdfEbook].include?(klass)
              it { expect(subject.watermarkable?) .not_to eq instance.watermarkable? }
            else
              it { expect(subject.watermarkable?)     .to eq instance.watermarkable? }
            end
          end
        end
      end
    end
  end
end
