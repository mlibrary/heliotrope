# frozen_string_literal: true
require 'spec_helper'

describe ActiveTriples::PersistenceStrategy do
  let(:klass) { Class.new { include ActiveTriples::PersistenceStrategy } }
  subject { klass.new }

  describe '#persist!' do
    it 'raises as not implemented' do
      expect { subject.persist! }.to raise_error NotImplementedError 
    end
  end

  describe '#erase_old_resource' do
    it 'raises as not implemented' do
      expect { subject.erase_old_resource }.to raise_error NotImplementedError 
    end
  end

  describe '#reload' do
    it 'raises as not implemented' do
      expect { subject.reload }.to raise_error NotImplementedError 
    end
  end
end
