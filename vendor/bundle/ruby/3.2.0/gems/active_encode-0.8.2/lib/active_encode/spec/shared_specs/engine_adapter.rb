# frozen_string_literal: true
RSpec.shared_examples 'an ActiveEncode::EngineAdapter' do |*_flags|
  before do
    raise 'adapter must be set with `let(:created_job)`' unless defined? created_job
    raise 'adapter must be set with `let(:running_job)`' unless defined? running_job
    raise 'adapter must be set with `let(:canceled_job)`' unless defined? canceled_job
    raise 'adapter must be set with `let(:completed_job)`' unless defined? completed_job
    raise 'adapter must be set with `let(:failed_job)`' unless defined? failed_job
    raise 'adapter must be set with `let(:completed_tech_metadata)`' unless defined? completed_tech_metadata
    raise 'adapter must be set with `let(:completed_output)`' unless defined? completed_output
    raise 'adapter must be set with `let(:failed_tech_metadata)`' unless defined? failed_tech_metadata
  end

  it { is_expected.to respond_to :create }
  it { is_expected.to respond_to :find }
  it { is_expected.to respond_to :cancel }

  describe "#create" do
    subject { created_job }

    it 'returns an ActiveEncode::Base object' do
      expect(subject.class).to be ActiveEncode::Base
    end
    it { expect(subject.id).to be_present }
    it { is_expected.to be_running }
    it { expect(subject.current_operations).to be_empty }
    it { expect(subject.percent_complete).to be < 100 }
    it { expect(subject.errors).to be_empty }
    it { expect(subject.created_at).to be_kind_of Time }
    it { expect(subject.updated_at).to be_kind_of Time }

    it 'input is a valid ActiveEncode::Input object' do
      expect(subject.input).to be_a ActiveEncode::Input
      expect(subject.input).to be_valid
    end

    it 'output has only valid ActiveEncode::Output objects' do
      expect(subject.output).to be_a Array
      subject.output.each do |out|
        expect(out).to be_a ActiveEncode::Output
        expect(out).to be_valid
      end
    end
  end

  describe "#find" do
    context "a running encode" do
      subject { running_job }

      it 'returns an ActiveEncode::Base object' do
        expect(subject.class).to be ActiveEncode::Base
      end
      it { expect(subject.id).to be_present }
      it { is_expected.to be_running }
      it { expect(subject.percent_complete).to be_positive }
      it { expect(subject.errors).to be_empty }
      it { expect(subject.created_at).to be_kind_of Time }
      it { expect(subject.updated_at).to be >= subject.created_at }

      it 'input is a valid ActiveEncode::Input object' do
        expect(subject.input).to be_a ActiveEncode::Input
        expect(subject.input).to be_valid
      end

      it 'output has only valid ActiveEncode::Output objects' do
        expect(subject.output).to be_a Array
        subject.output.each do |out|
          expect(out).to be_a ActiveEncode::Output
          expect(out).to be_valid
        end
      end
    end

    context "a cancelled encode" do
      subject { canceled_job }

      it 'returns an ActiveEncode::Base object' do
        expect(subject.class).to be ActiveEncode::Base
      end
      it { expect(subject.id).to be_present }
      it { is_expected.to be_cancelled }
      it { expect(subject.percent_complete).to be_positive }
      it { expect(subject.errors).to be_empty }
      it { expect(subject.created_at).to be_kind_of Time }
      it { expect(subject.updated_at).to be >= subject.created_at }

      it 'input is a valid ActiveEncode::Input object' do
        expect(subject.input).to be_a ActiveEncode::Input
        expect(subject.input).to be_valid
      end

      it 'output has only valid ActiveEncode::Output objects' do
        expect(subject.output).to be_a Array
        subject.output.each do |out|
          expect(out).to be_a ActiveEncode::Output
          expect(out).to be_valid
        end
      end
    end

    context "a completed encode" do
      subject { completed_job }

      it 'returns an ActiveEncode::Base object' do
        expect(subject.class).to be ActiveEncode::Base
      end
      it { expect(subject.id).to be_present }
      it { is_expected.to be_completed }
      it { expect(subject.percent_complete).to eq 100 }
      it { expect(subject.errors).to be_empty }
      it { expect(subject.created_at).to be_kind_of Time }
      it { expect(subject.updated_at).to be > subject.created_at }

      it 'input is a valid ActiveEncode::Input object' do
        expect(subject.input).to be_a ActiveEncode::Input
        expect(subject.input).to be_valid
      end

      it 'input has technical metadata' do
        expect(subject.input.as_json.symbolize_keys).to include completed_tech_metadata
      end

      it 'output has only valid ActiveEncode::Output objects' do
        expect(subject.output).to be_a Array
        subject.output.each do |out|
          expect(out).to be_a ActiveEncode::Output
          expect(out).to be_valid
        end
      end

      it 'output has technical metadata' do
        subject.output.each do |output|
          expected_output = completed_output.find { |expected_out| expected_out[:id] == output.id }
          expect(output.as_json.symbolize_keys).to include expected_output
        end
      end
    end

    context "a failed encode" do
      subject { failed_job }

      it 'returns an ActiveEncode::Base object' do
        expect(subject.class).to be ActiveEncode::Base
      end
      it { expect(subject.id).to be_present }
      it { is_expected.to be_failed }
      it { expect(subject.percent_complete).to be_positive }
      it { expect(subject.errors).not_to be_empty }
      it { expect(subject.created_at).to be_kind_of Time }
      it { expect(subject.updated_at).to be > subject.created_at }

      it 'input is a valid ActiveEncode::Input object' do
        expect(subject.input).to be_a ActiveEncode::Input
        expect(subject.input).to be_valid
      end

      it 'input has technical metadata' do
        expect(subject.input.as_json.symbolize_keys).to include failed_tech_metadata
      end

      it 'output has only valid ActiveEncode::Output objects' do
        expect(subject.output).to be_a Array
        subject.output.each do |out|
          expect(out).to be_a ActiveEncode::Output
          expect(out).to be_valid
        end
      end
    end
  end

  describe "#cancel!" do
    subject { cancelling_job.cancel! }

    it 'returns an ActiveEncode::Base object' do
      expect(subject.class).to be ActiveEncode::Base
    end
    it { expect(subject.id).to eq cancelling_job.id }
    it { is_expected.to be_cancelled }
    it { expect(subject.percent_complete).to be_positive }
    it { expect(subject.errors).to be_empty }
    it { expect(subject.created_at).to be_kind_of Time }
    it { expect(subject.updated_at).to be >= subject.created_at }

    it 'input is a valid ActiveEncode::Input object' do
      expect(subject.input).to be_a ActiveEncode::Input
      expect(subject.input).to be_valid
    end

    it 'output has only valid ActiveEncode::Output objects' do
      expect(subject.output).to be_a Array
      subject.output.each do |out|
        expect(out).to be_a ActiveEncode::Output
        expect(out).to be_valid
      end
    end
  end

  describe "reload" do
    subject { running_job.reload }

    it 'returns an ActiveEncode::Base object' do
      expect(subject.class).to be ActiveEncode::Base
    end
    it { expect(subject.id).to be_present }
    it { expect(subject.percent_complete).to be_positive }
    it { expect(subject.errors).to be_empty }
    it { expect(subject.created_at).to be_kind_of Time }
    it { expect(subject.updated_at).to be >= subject.created_at }

    it 'input is a valid ActiveEncode::Input object' do
      expect(subject.input).to be_a ActiveEncode::Input
      expect(subject.input).to be_valid
    end

    it 'output has only valid ActiveEncode::Output objects' do
      expect(subject.output).to be_a Array
      subject.output.each do |out|
        expect(out).to be_a ActiveEncode::Output
        expect(out).to be_valid
      end
    end
  end
end
