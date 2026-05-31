# frozen_string_literal: true

describe Blacklight::AccessControls::Config do
  let(:config) { described_class.new }

  describe '#user_model' do
    it 'has a default value' do
      expect(config.user_model).to eq 'User'
    end

    it 'can be set to a non-default value' do
      config.user_model = 'Student'
      expect(config.user_model).to eq 'Student'
    end
  end

  describe '#discover_group_field' do
    subject { config.discover_group_field }

    it 'has a default value' do
      expect(subject).to eq 'discover_access_group_ssim'
    end

    it 'can be set to a non-default value' do
      config.discover_group_field = 'something else'
      expect(subject).to eq 'something else'
    end
  end

  describe '#discover_user_field' do
    subject { config.discover_user_field }

    it 'has a default value' do
      expect(subject).to eq 'discover_access_person_ssim'
    end

    it 'can be set to a non-default value' do
      config.discover_user_field = 'something else'
      expect(subject).to eq 'something else'
    end
  end

  describe '#read_group_field' do
    subject { config.read_group_field }

    it 'has a default value' do
      expect(subject).to eq 'read_access_group_ssim'
    end

    it 'can be set to a non-default value' do
      config.read_group_field = 'something else'
      expect(subject).to eq 'something else'
    end
  end

  describe '#read_user_field' do
    subject { config.read_user_field }

    it 'has a default value' do
      expect(subject).to eq 'read_access_person_ssim'
    end

    it 'can be set to a non-default value' do
      config.read_user_field = 'something else'
      expect(subject).to eq 'something else'
    end
  end

  describe '#download_group_field' do
    subject { config.download_group_field }

    it 'has a default value' do
      expect(subject).to eq 'download_access_group_ssim'
    end

    it 'can be set to a non-default value' do
      config.download_group_field = 'something else'
      expect(subject).to eq 'something else'
    end
  end

  describe '#download_user_field' do
    subject { config.download_user_field }

    it 'has a default value' do
      expect(subject).to eq 'download_access_person_ssim'
    end

    it 'can be set to a non-default value' do
      config.download_user_field = 'something else'
      expect(subject).to eq 'something else'
    end
  end
end
