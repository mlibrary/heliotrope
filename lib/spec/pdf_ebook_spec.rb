# frozen_string_literal: true

RSpec.describe PDFEbook do
  describe '#logger' do
    it 'attribute getter' do
      expect { described_class.logger }.not_to raise_error
    end
    it 'attribute setter' do
      expect { described_class.logger = nil }.not_to raise_error
    end
  end

  describe '#configure' do
    before { described_class.reset_configured_flag }

    it 'setup block yields subject' do
      setup_config = nil
      described_class.configure do |config|
        setup_config = config
      end
      is_expected.to eq setup_config
    end

    it 'subject is configured' do
      described_class.configure do |config|
      end
      expect(subject.configured?).to be true
    end
  end
end
