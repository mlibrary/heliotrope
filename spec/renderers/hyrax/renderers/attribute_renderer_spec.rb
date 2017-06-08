# frozen_string_literal: true

require 'rails_helper'

describe Hyrax::Renderers::AttributeRenderer do
  let(:field) { :section_title }

  describe "sort_by option" do
    subject { renderer.render }
    let(:renderer) { described_class.new(field,
                                         ['Chapter 3', 'Chapter 1'],
                                         sort_by: ['Chapter 1', 'Chapter 2', 'Chapter 3']) }
    it { expect(subject).to match(/Chapter 1.*Chapter 3/) }
    it { expect(subject).to_not match(/Chapter 3.*Chapter 1/) }
    it { expect(subject).to_not match(/Chapter 2/) }
  end
end
