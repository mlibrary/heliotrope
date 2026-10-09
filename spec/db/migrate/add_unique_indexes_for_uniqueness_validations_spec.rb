# frozen_string_literal: true

require 'rails_helper'
require_relative '../../../db/migrate/20260730000001_add_unique_indexes_for_uniqueness_validations'

RSpec.describe AddUniqueIndexesForUniquenessValidations do
  subject(:migration) { described_class.new }

  let(:connection) { instance_double(ActiveRecord::ConnectionAdapters::Mysql2Adapter) }
  let(:indexes) do
    [
      [:ebook_table_of_contents_caches, :noid],
      [:presses, :name],
      [:presses, :subdomain],
      [:presses, :press_url]
    ]
  end

  before do
    allow(migration).to receive(:connection).and_return(connection)
  end

  it 'adds all missing unique indexes' do
    indexes.each do |table, column|
      allow(connection).to receive(:index_exists?).with(table.to_s, column, unique: true).and_return(false)
      expect(connection).to receive(:add_index).with(table.to_s, column, unique: true)
    end

    migration.up
  end

  it 'resumes after a partially loaded schema or partially applied migration' do
    indexes.each do |table, column|
      exists = column == :noid || column == :name
      allow(connection).to receive(:index_exists?).with(table.to_s, column, unique: true).and_return(exists)
      if exists
        expect(connection).not_to receive(:add_index).with(table.to_s, column, unique: true)
      else
        expect(connection).to receive(:add_index).with(table.to_s, column, unique: true)
      end
    end

    migration.up
  end

  it 'does nothing when all unique indexes already exist' do
    allow(connection).to receive(:index_exists?).and_return(true)
    expect(connection).not_to receive(:add_index)

    migration.up
  end

  it 'removes existing unique indexes on rollback' do
    indexes.each do |table, column|
      allow(connection).to receive(:index_exists?).with(table.to_s, column, unique: true).and_return(true)
      expect(connection).to receive(:remove_index).with(table.to_s, column)
    end

    migration.down
  end

  it 'does not remove missing indexes on rollback' do
    allow(connection).to receive(:index_exists?).and_return(false)
    expect(connection).not_to receive(:remove_index)

    migration.down
  end

  it 'surfaces index creation errors instead of marking the migration successful' do
    allow(connection).to receive(:index_exists?).and_return(false)
    allow(connection).to receive(:add_index).and_raise(ActiveRecord::RecordNotUnique)

    expect { migration.up }.to raise_error(ActiveRecord::RecordNotUnique)
  end
end
