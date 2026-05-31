require 'spec_helper'


class OtherTemplate < Noid::Template
end

describe Noid::Template do
  context 'with a valid template' do
    let(:template) { '.redek' }
    it 'initializes without raising' do
      expect { described_class.new(template) }.not_to raise_error
    end
    it 'stringifies cleanly as the template string' do
      expect(described_class.new(template).to_s).to eq(template)
    end
    describe 'comparison' do
      let(:object) { described_class.new(template) }
      it 'unrelated object is not equivalent' do
        expect(object).not_to eq(Array.new)
      end
      it 'descendant object with same template is equivalent' do
        expect(object).to eq(OtherTemplate.new(object.template))
      end
      it 'same templates produce equivalent objects' do
        expect(object).to eq(described_class.new(object.template))
      end
      it 'different templates produce non-equivalent objects' do
        expect(object).not_to eq(described_class.new('.redddek'))
        expect(object).not_to eq(OtherTemplate.new('.redddek'))
      end
    end
  end
  context 'with a bogus template' do
    let(:template) { 'foobar' }
    it 'raises Noid::TemplateError' do
      expect { described_class.new(template) }.to raise_error(Noid::TemplateError)
    end
  end
end
