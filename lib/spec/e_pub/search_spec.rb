# frozen_string_literal: true

RSpec.describe EPub::Search do
  describe '#search' do
    subject { described_class.new(EPub::Publication.from_directory(@root_path)).search(query) }

    before do
      @noid = '999999991'
      @root_path = UnpackHelper.noid_to_root_path(@noid, 'epub')
      @file = './spec/fixtures/fake_epub01.epub'
      UnpackHelper.unpack_epub(@noid, @root_path, @file)
      UnpackHelper.create_search_index(@root_path)
      allow(EPub.logger).to receive(:info).and_return(nil)
    end

    after do
      FileUtils.rm_rf(Dir[File.join('./tmp', 'rspec_derivatives')])
    end

    context 'db results empty' do
      let(:query) { 'nobody' }

      it { is_expected.to match(q: query, highlight_off: "no", search_results: [], timeout: 0) }
    end

    context 'db results non empty' do
      let(:query) { 'everybody' }

      it do
        expect(subject[:q]).to eq "everybody"
        expect(subject[:search_results].length).to eq 2

        expect(subject[:search_results][0][:cfi]).to eq "/6/2[Chapter01]!/4/8,/1:23,/1:32"
        expect(subject[:search_results][0][:title]).to eq "Damage report!"
        expect(subject[:search_results][0][:snippet]).to eq "Why don't we just give everybody a promotion and call it a night - 'Commander'? Fate."

        expect(subject[:search_results][1][:cfi]).to eq "/6/6[Chapter03]!/4/12,/1:781,/1:790"
        expect(subject[:search_results][1][:title]).to eq "Mr. Crusher, ready a collision course with the Borg ship."
        expect(subject[:search_results][1][:snippet]).to eq "long can two people talk about nothing? Why don't we just give everybody a promotion and call it a night - 'Commander'?"
      end
    end

    context "with multiple matches in deeply nested nodes" do
      let(:query) { 'star wars' }

      it "doesn't include duplicate snippets" do
        expect(subject[:q]).to eq 'star wars'
        @snippets = subject[:search_results].filter_map { |result| result[:snippet].presence }
        expect(@snippets.length).to eq @snippets.uniq.length
      end
    end

    context "with a timeout" do
      let(:query) { 'can' }

      it "has a non-zero timeout because the search timed out" do
        stub_const("EPub::Search::TIME_OUT", 1) # 1 millisecond
        allow(EPub.logger).to receive(:info).and_return(true)
        expect(subject[:timeout].to_i).to be > 0
      end
    end
  end

  describe "#node_query_match" do
    subject { described_class.new(double("publication")) }

    let(:doc) { Nokogiri::XML("<html><body><p>We will match search.</p><p>We will not match searched.<p></body></html>") }

    context "when looking for 'search' it matches 'search'" do
      let(:node) { doc.xpath("//p")[0].children[0] }
      let(:query) { "search" }

      it { expect(subject.node_query_match(node, query)).to eq 14 }
    end

    context "when looking for 'search' it will not match 'searched'" do
      let(:node) { doc.xpath("//p")[1].children[0] }
      let(:query) { "search" }

      it { expect(subject.node_query_match(node, query)).to eq nil }
    end

    context "regexes don't work: looking for sea*.ch will not match 'search'" do
      let(:node) { doc.xpath("//p")[0].children[0] }
      let(:query) { "sea*.ch" }

      it { expect(subject.node_query_match(node, query)).to eq nil }
    end
  end
end
