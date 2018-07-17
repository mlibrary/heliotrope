# frozen_string_literal: true

RSpec.describe EPub::Cfi do
  let(:chapter) do
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

  let(:doc) { Nokogiri::XML(chapter) }

  before do
    doc.remove_namespaces!
  end

  describe "first paragraph match on 'hysteria'" do
    let(:node) { doc.xpath("//body/p").first.children[4] }
    let(:query) { "hysteria" }
    let(:offset) { 0 }
    let(:cfi) { described_class.from(node, query, offset) }

    it "finds the correct section" do
      expect(cfi.section).to eq 5
    end

    it "finds the correct range" do
      expect(cfi.range).to eq '/5:1,/5:9'
    end

    it "finds the correct cfi" do
      expect(cfi.cfi).to eq '/4/2,/5:1,/5:9'
    end
  end

  describe "second paragraph match on 'emanating'" do
    let(:node) { doc.xpath("//body/p")[1].children[7] }
    let(:query) { "emanating" }
    let(:offset) { 0 }
    let(:cfi) { described_class.from(node, query, offset) }

    it "finds the correct section" do
      expect(cfi.section).to eq 7
    end

    it "finds the correct range" do
      expect(cfi.range).to eq "/7:354,/7:363"
    end

    it "find the correct cfi" do
      expect(cfi.cfi).to eq '/4/4,/7:354,/7:363'
    end
  end

  describe "last paragraph first instance of 'glarf'" do
    let(:node) { doc.xpath("//body/p").last.children[0] }
    let(:query) { "glarf" }
    let(:offset) { 0 }
    let(:cfi) { described_class.from(node, query, offset) }

    it "finds the correct section" do
      expect(cfi.section).to eq 1
    end

    it "finds the correct range" do
      expect(cfi.range).to eq "/1:0,/1:5"
    end

    it "finds the correct cfi" do
      expect(cfi.cfi).to eq "/4/6,/1:0,/1:5"
    end
  end

  describe "last paragraph instances of 'glarf'" do
    let(:node) { doc.xpath("//body/p").last.children[2] }
    let(:query) { "glarf" }
    let(:offset) { 0 }
    let(:cfi) { described_class.from(node, query, offset) }

    it "finds the cfi of the first instance" do
      expect(cfi.cfi).to eq "/4/6,/3:6,/3:11"
    end

    it "has the position after the first instance" do
      expect(cfi.pos1).to eq 11
    end

    it "finds the cfi of the last instance" do
      next_cfi = described_class.from(node, query, cfi.pos1 + 1)
      expect(next_cfi.cfi).to eq "/4/6,/3:12,/3:17"
    end
  end

  describe "with incorrect non-text node parameter" do
    let(:node) { doc.xpath("//body/p").last }
    let(:query) { "glarf" }
    let(:offset) { 0 }
    let(:cfi) { described_class.from(node, query, offset) }

    it "is a null object" do
      expect(cfi).to be_an_instance_of(EPub::CfiNullObject)
    end
    it "the null object responds to node" do
      expect(cfi.respond_to?(:node)).to be true
    end
    it "the null object's node is empty" do
      expect(cfi.node.children.blank?).to be true
    end
  end

  describe "with an empty query" do
    let(:node) { doc.xpath("//body/p").last.children[2] }
    let(:query) { "" }
    let(:offset) { 0 }
    let(:cfi) { described_class.from(node, query, offset) }

    it "returns a null object" do
      expect(cfi).to be_an_instance_of(EPub::CfiNullObject)
    end
  end
end
