# frozen_string_literal: true

RSpec.describe PDFEbook::Publication do
  describe '#new' do
    it { expect { is_expected }.to raise_error(NoMethodError) }
  end

  describe "with a test PDF" do
    context "using #from_path_id" do
      before do
        @noid = '99999999'
        @file = './spec/fixtures/fake_pdf01.pdf'
      end

      describe "#intervals" do
        subject { described_class.from_path_id(@file, @noid) }

        it { is_expected.to be_an_instance_of(described_class) }

        it "has 5 intervals" do
          expect(subject.intervals.count).to be 5
        end

        describe "interval 1" do
          subject { described_class.from_path_id(@file, @noid).intervals[0] }

          it "has title Front Cover" do
            expect(subject.title).to eq "Front Cover"
          end
          it "has level 1" do
            expect(subject.level).to eq 1
          end
          it "has the cfi of" do
            expect(subject.cfi).to eq 'page=1'
          end
        end

        describe "interval 4" do
          subject { described_class.from_path_id(@file, @noid).intervals[3] }

          it "has title Front Cover" do
            expect(subject.title).to eq "Section 2.1"
          end
          it "has level 2" do
            expect(subject.level).to eq 2
          end
          it "has the cfi of" do
            expect(subject.cfi).to eq 'page=6'
          end
        end
      end
    end
  end

  describe "with no PDF" do
    context "using #from_path_id" do
      before do
        @noid = '99999999'
        @file = 'not-a-file.pdf'
        allow(PDFEbook.logger).to receive(:info).and_return(nil) # don't print log errors in specs
      end

      describe "#intervals" do
        subject { described_class.from_path_id(@file, @noid) }

        it { is_expected.to be_an_instance_of(PDFEbook::PublicationNullObject) }

        it "has no intervals, but does not throw an error" do
          expect(subject.intervals).to eq []
          expect(subject.intervals.count).to be 0
        end
      end
    end
  end
end
