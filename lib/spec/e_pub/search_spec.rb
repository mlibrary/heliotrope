# frozen_string_literal: true

RSpec.describe EPub::Search do
  before(:all) do # rubocop:disable RSpec/BeforeAfterAll
    @id = 'validnoid'
    @file = './spec/fixtures/fake_epub01.epub'
    EPub::Publication.from(id: @id, file: @file)
  end
  after(:all) { EPub::Publication.from(@id).purge } # rubocop:disable RSpec/BeforeAfterAll

  describe '#search' do
    subject { described_class.new(EPub::Publication.from(@id)).search(query) }

    context 'db results empty' do
      let(:query) { 'nobody' }
      it { is_expected.to match(q: query) }
    end

    context 'db results non empty' do
      let(:query) { 'everybody' }
      it do
        is_expected.to match(q: "everybody",
                             search_results: [{ cfi: "/6/2[Chapter01]!/4/8,/1:23,/1:32",
                                                title: "Damage report!",
                                                snippet: "...Why don't we just give everybody a promotion and call it a night - 'Commander'? Fate..." },
                                              { cfi: "/6/6[Chapter03]!/4/12,/1:781,/1:790",
                                                title: "Mr. Crusher, ready a collision course with the Borg ship.",
                                                snippet: "...people talk about nothing? Why don't we just give everybody a promotion and call it a night - 'Commander'?..." }])
      end
    end
  end
end
