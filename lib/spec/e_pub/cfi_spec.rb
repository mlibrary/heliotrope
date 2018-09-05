# frozen_string_literal: true

RSpec.describe EPub::CFI do
  describe '#from' do
    let(:text) { "<html><head><body><p>Ok</p></body></html>" }
    let(:doc)  { Nokogiri::XML(text) }

    context 'with text parameters' do
      subject { described_class.from(node, pos0, pos1) }

      let(:node) { doc.xpath("//body/p").first.children.first }
      let(:pos0) { 0 }
      let(:pos1) { 2 }

      it { expect(subject).to be_an_instance_of(EPub::CFI::Text) }
    end

    context 'with an element parameter' do
      subject { described_class.from(node) }

      let(:node) { doc.xpath("//body/p").first }

      it { expect(subject).to be_an_instance_of(EPub::CFI::Element) }
    end

    context 'with bad paramters' do
      subject { described_class.from("never", "hampsters!") }

      it { expect(subject).to be_an_instance_of(EPub::CFI::NullObject) }
    end
  end

  describe '#cfi' do
    context 'for element' do
      subject { described_class.from(node).cfi }

      let(:xml) do
        <<-XML
        <html>
          <head>
            <title>Identifying Hampsters</title>
          </head>
          <body>
            <section id="start">
              <p>Bears are not hampsters. In fact, they're not any kind of ham at all!</p>
              <div id="big_idea">
                <div class="data-poi">
                  <img src="smiling-lizard-wearing-a-hampster-suit.jpg">
                  <p class="caption">Lizards are also not hampsters. Beware their tickery.</p>
                </div>
              </div>
              <p>Bananas may be oranges, but it's hard to <b id="know">know</b> for sure. Consult an expert.</p>
            </section>
          </body>
        </html>
        XML
      end

      let(:doc) { Nokogiri::XML(xml).remove_namespaces! }

      context 'section id "start"' do
        let(:node) { doc.at_css(%([id="start"])) }

        it { expect(subject).to eq "/4/2[start]" }
      end

      context 'class "data-poi"' do
        let(:node) { doc.at_css(%([class="data-poi"])) }

        it { expect(subject).to eq "/4/2[start]/4[big_idea]/2" }
      end

      context 'b id "know"' do
        let(:node) { doc.at_css(%([id="know"])) }

        it { expect(subject).to eq "/4/2[start]/4[big_idea]/4/2[know]" }
      end
    end

    context 'for text' do
      subject { described_class.from(node, pos0, pos1).cfi }

      let(:xml) do
        <<-EOT
        <html>
          <head>
            <title>Stuff about Things</title>
          </head>
          <body>
            <p>Human sacrifice, cats and dogs <i>living</i> together... <i>mass</i> hysteria!</p>
            <p class="noindent"><a href="10_Chapter02.xhtml">Chapters 2</a>&#8211;<a href="12_Chapter04.xhtml">4</a> focused largely on how the entertainment industry can fashion a text at its outskirts, using paratexts to set the parameters of genre, style, address, value, and meaning. In this chapter, however, I hope to have shown that audience members are involved in this fashioning of the text not simply as consumers of text and paratext, but as creators of their own paratexts. The industry usually has considerable interest in trying to set its own textual parameters, and it will at times reinforce this semiotic act with legal ones, literally closing off opportunities for its texts to grow in certain directions. But audience members have a built-in interest in fashioning the text themselves. At a rudimentary&#8212;though by no means insignificant&#8212;level, the paratext of everyday discussion will forever play a constitutive role in creating the text. How we talk about texts affects how <span epub:type="pagebreak" id="page_174" title="174"/>others talk about and consume them, as was seen in <a href="12_Chapter04.xhtml">chapter 4</a>. We can also &#8220;talk&#8221; through more elaborate forms of paratexts, whether they be spoilers, vids, recaps, wikis, reviews, or other viewer-end paratexts such as websites, campaigns, viewing parties, or so on. Some such forms of &#8220;talk&#8221; will be louder and more readily accessible than others, some directed at small communities of like-minded audiences, some emanating out to the public sphere more generally. The latter may even in due course come to determine the public understanding of a text. Others allow viable alternatives to the public script to emerge, thereby multiplying the text into various versions. All, though, underline the considerable power of viewer-end paratexts to set or change the terms by which we make sense of film and television, and, hence, to add or subtract depth and breadth to a text and its storyworld.</p>
            <p>glarf shmorg<blockquote>gnerp</blockqoute>qwerm glarf glarf.</p>
          </body>
        </html>
        EOT
      end

      let(:doc) { Nokogiri::XML(xml).remove_namespaces! }
      let(:pos0) { node.content.index(/#{Regexp.escape(query)}\W/i, offset) }
      let(:pos1) { pos0 + query.length }

      describe "first paragraph match on 'hysteria'" do
        let(:node) { doc.xpath("//body/p").first.children[4] }
        let(:query) { "hysteria" }
        let(:offset) { 0 }

        it "finds the correct cfi" do
          expect(subject).to eq '/4/2,/5:1,/5:9'
        end
      end

      describe "second paragraph match on 'emanating'" do
        let(:node) { doc.xpath("//body/p")[1].children[7] }
        let(:query) { "emanating" }
        let(:offset) { 0 }

        it "find the correct cfi" do
          expect(subject).to eq '/4/4,/7:354,/7:363'
        end
      end

      describe "last paragraph first instance of 'glarf'" do
        let(:node) { doc.xpath("//body/p").last.children[0] }
        let(:query) { "glarf" }
        let(:offset) { 0 }

        it "finds the correct cfi" do
          expect(subject).to eq "/4/6,/1:0,/1:5"
        end
      end

      describe "last paragraph instances of 'glarf'" do
        let(:node) { doc.xpath("//body/p").last.children[2] }
        let(:query) { "glarf" }
        let(:offset) { 0 }

        it "finds the cfi of the first instance" do
          expect(subject).to eq "/4/6,/3:6,/3:11"
        end

        it "finds the cfi of the last instance" do
          next_pos0 = node.content.index(/#{Regexp.escape(query)}\W/i, pos1 + 1)
          next_pos1 = next_pos0 + query.length
          next_cfi = described_class.from(node, next_pos0, next_pos1).cfi
          expect(next_cfi).to eq "/4/6,/3:12,/3:17"
        end
      end
    end

    context 'with the null object' do
      subject { described_class.from("never", "hampsters!").cfi }

      it { expect(subject).to eq '/' }
    end
  end
end
