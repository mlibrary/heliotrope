# frozen_string_literal: true

require 'nokogiri'

RSpec.describe EPub::BridgeToWebgl do
  let(:publication) { double('publication') }
  let(:id) { 'epubid' }
  let(:chapters) do
    [
      EPub::Chapter.send(:new,
                         'chapter1',
                         'chapter1.html',
                         'Chapter 1',
                         "/6/2[chapter1]!",
                         Nokogiri::XML(chapter1))
    ]
  end
  let(:chapter1) do
    <<-EOT
    <html>
      <head>
        <title>Chapter 1</title>
      </head>
      <body>
        <div id="div1">
          <p data-poi="par1">These are some things.</p>
        </div>
        <div id="div2">
          <p>Not these things.</p>
        </div>
        <div id="div3">
          <p>No.</p>
          <div id="div4">
            <p id="para2" data-poi="par2">Yes</p>
          </div>
        </div>
      </body>
    </html>
    EOT
  end

  describe "#cache" do
    it "creates the POI to CFI mapping" do
      allow(File).to receive(:write).and_return(nil)
      allow(EPub.logger).to receive(:info).and_return(nil)
      allow(publication).to receive(:id).and_return(id)
      allow(publication).to receive(:chapters).and_return(chapters)

      described_class.cache(publication)

      expect(described_class.mapping).to eq [{ poi: "par1", cfi: "/6/2[chapter1]!/4/2[div1]/2" },
                                             { poi: "par2", cfi: "/6/2[chapter1]!/4/6[div3]/4[div4]/2[para2]" }]
    end
  end
end
