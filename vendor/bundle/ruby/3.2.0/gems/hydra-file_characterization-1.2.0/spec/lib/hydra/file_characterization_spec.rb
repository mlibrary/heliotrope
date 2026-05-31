require 'spec_helper'
require 'hydra/file_characterization'
require 'hydra/file_characterization/characterizer'

module Hydra

  describe FileCharacterization do

    describe '.characterize', unless: ENV['TRAVIS'] do
      describe "for content in memory" do
        let(:content) { "class Test; end\n" }
        let(:filename) { 'test.rb' }
        subject { Hydra::FileCharacterization.characterize(content, filename, tool_names) }

        describe 'for fits' do
          let(:tool_names) { [:fits] }
          it { is_expected.to match(/#{'<identity format="Plain text" mimetype="text/plain"'}/) }
        end

        describe 'with configured path' do
          let(:tool_path) do
            `which fits || which fits.sh`.strip
          end

          it {
            response = Hydra::FileCharacterization.characterize(content, filename, :fits) do |config|
              config[:fits] = tool_path
            end

            expect(response).to match(/#{'<identity format="Plain text" mimetype="text/plain"'}/)
          }
        end

        describe 'with multiple runs' do
          it {
            response_1, response_2, response_3 = Hydra::FileCharacterization.characterize(content, filename, :fits, :fits)
            expect(response_1).to match(/#{'<identity format="Plain text" mimetype="text/plain"'}/)
            expect(response_2).to match(/#{'<identity format="Plain text" mimetype="text/plain"'}/)
            expect(response_3).to be_nil
          }
        end

        describe 'for a bogus tool' do
          let(:tool_names) { [:cookie_monster] }
          it {
            expect {
              subject
            }.to raise_error(Hydra::FileCharacterization::ToolNotFoundError)
          }
        end

        describe 'for a mix of bogus and valid tools' do
          let(:tool_names) { [:fits, :cookie_monster] }
          it {
            expect {
              subject
            }.to raise_error(Hydra::FileCharacterization::ToolNotFoundError)
          }
        end

        describe 'for no tools' do
          let(:tool_names) { nil }
          it { should eq [] }
        end
      end

      describe "for a file on disk" do
        let(:file) { File.open(fixture_file('brendan_behan.jpeg')) }
        describe "without path specified" do
          subject { Hydra::FileCharacterization.characterize(file, tool_names) }

          describe 'for fits' do
            let(:tool_names) { [:fits] }
            it { should match(/#{'<identity format="JPEG File Interchange Format" mimetype="image/jpeg"'}/) }
          end
        end
        describe "with path specified" do
          let(:file) { File.open(fixture_file('brendan_behan.jpeg')) }
          subject { Hydra::FileCharacterization.characterize(file, 'Brendan.jpg', tool_names) }

          describe 'for fits' do
            let(:tool_names) { [:fits] }
            it { should match(/#{'<identity format="JPEG File Interchange Format" mimetype="image/jpeg"'}/) }
          end
        end
      end
    end
    describe '.configure' do
      let(:content) { "class Test; end\n" }
      let(:filename) { 'test.rb' }
      around do |example|
        old_tool_path = Hydra::FileCharacterization::Characterizers::Fits.tool_path
        example.run
        Hydra::FileCharacterization::Characterizers::Fits.tool_path = old_tool_path
      end

      it 'without configuration', unless: ENV['CI'] do
        Hydra::FileCharacterization.configure do |config|
          config.tool_path(:fits, nil)
        end
        response = Hydra::FileCharacterization.characterize(content, filename, :fits)
        expect(response).to match(/#{'<identity format="Plain text" mimetype="text/plain"'}/)

      end
    end

  end
end
