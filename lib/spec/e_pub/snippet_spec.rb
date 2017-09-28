# frozen_string_literal: true

require 'nokogiri'

RSpec.describe EPub::Snippet do
  let(:chapter) do
    <<-EOT
    <html>
      <head>
        <title>Stuff about Things</title>
      </head>
      <body>
      <p>The one grand stage where he enacted all his various parts so manifold, was his vice-bench; a long rude ponderous table furnished with several vices, of different sizes, and both of iron and of wood. At all times except when whales were alongside, this bench was securely lashed athwartships against the rear of the Try-works.</p>
      <p class="noindent"><a href="10_Chapter02.xhtml">Chapters 2</a>&#8211;<a href="12_Chapter04.xhtml">4</a> focused largely on how the entertainment industry can fashion a text at its outskirts, using paratexts to set the parameters of genre, style, address, value, and meaning. In this chapter, however, I hope to have shown that audience members are involved in this fashioning of the text not simply as consumers of text and paratext, but as creators of their own paratexts. The industry usually has considerable interest in trying to set its own textual parameters, and it will at times reinforce this semiotic act with legal ones, literally closing off opportunities for its texts to grow in certain directions. But audience members have a built-in interest in fashioning the text themselves. At a rudimentary&#8212;though by no means insignificant&#8212;level, the paratext of everyday discussion will forever play a constitutive role in creating the text. How we talk about texts affects how <span epub:type="pagebreak" id="page_174" title="174"/>others talk about and consume them, as was seen in <a href="12_Chapter04.xhtml">chapter 4</a>. We can also &#8220;talk&#8221; through more elaborate forms of paratexts, whether they be spoilers, vids, recaps, wikis, reviews, or other viewer-end paratexts such as websites, campaigns, viewing parties, or so on. Some such forms of &#8220;talk&#8221; will be louder and more readily accessible than others, some directed at small communities of like-minded audiences, some emanating out to the public sphere more generally. The latter may even in due course come to determine the public understanding of a text. Others allow viable alternatives to the public script to emerge, thereby multiplying the text into various versions. All, though, underline the considerable power of viewer-end paratexts to set or change the terms by which we make sense of film and television, and, hence, to add or subtract depth and breadth to a text and its storyworld.</p>
      <p class="indent">Lending the production of three films considerably more gravitas and mythic resonance, the DVDs&#8217; producers paint a picture of multiple other fellowships, innocent and struggling hobbits, charismatic rangers, and sage wizards. Most notably, the cast often transpose their filmic roles onto their own personages, or have the act performed by others. For instance, Orlando Bloom talks of what a privilege it was to come out of drama school and work with the likes of Ian McKellen, who, he notes, brought his &#8220;wise old wizard&#8221; ways to the cast, becoming a real-life Gandalf. Likewise, numerous cast and crew members discuss Viggo Mortensen&#8217;s charisma and leadership as if he was his character, the ranger who becomes king, Aragorn. The stuntmen claim that his hard work and dedication on the gruelling Helm&#8217;s Deep set inspired them. We learn of Mortensen&#8217;s personal pull in convincing cast and crew alike to camp out the night before a dawn shoot. Colleagues talk of him as an earthy, nature-loving man. And Second Unit Director John Mahaffi even declares, &#8220;If I was going into battle and I needed someone to be on my right shoulder, it would be Viggo.&#8221; Meanwhile, Dominic Monaghan and Billy Boyd provide much of the DVDs&#8217; comic relief, reprising their roles as the cheeky, prankster hobbits. In the cast commentary, they constantly toy with the film&#8217;s register of reality, joking that a dreary, rocky scene looks just like Manchester, for instance, or that the film&#8217;s huge dragon-like Balrog never bought a round when at the pub with them. Whereas most of the fifteen cast members contributing to the commentary were recorded individually, Monaghan and Boyd are recorded together, hence allowing their back-and-forth banter. Interestingly, too, while Elijah Wood and Sean Astin were recorded with them for the <i>Fellowship of the Ring</i> commentary, and similarly joked <span epub:type="pagebreak" id="page_93" title="93"/>around as carefree hobbits, the <i>Two Towers</i> commentary separates them from Monaghan and Boyd. Paralleling Frodo and Sam&#8217;s path into darkness, Wood and Astin&#8217;s commentary takes on a more pensive, reflective nature.</p>
      </body>
    </html>
    EOT
  end

  let(:doc) { Nokogiri::XML(chapter) }

  before do
    doc.remove_namespaces!
  end

  describe "snippet for 'athwartships'" do
    let(:node) { doc.xpath("//body/p").first.children[0] }
    let(:pos0) { 279 }
    let(:pos1) { 291 }

    it "creates the snippt" do
      expect(described_class.from(node, pos0, pos1).snippet).to eq '...es were alongside, this bench was securely lashed athwartships against the rear of the Try-works....'
    end
  end

  describe "snippet for 'carefree hobbits'" do
    let(:node) { doc.xpath("//body/p").last.children[4] }
    let(:pos0) { 10 }
    let(:pos1) { 26 }

    it "creates the snippet" do
      expect(described_class.from(node, pos0, pos1).snippet).to eq '...around as carefree hobbits, the Two Towers...'
    end
  end

  describe "snippet for 'emanating'" do
    let(:node) { doc.xpath("//body/p")[1].children[7] }
    let(:pos0) { 354 }
    let(:pos1) { 363 }

    it "creates the snippet" do
      expect(described_class.from(node, pos0, pos1).snippet).to eq '... small communities of like-minded audiences, some emanating out to the public sphere more generally. The latter...'
    end
  end

  describe "with a null node" do
    let(:node) { nil }
    let(:pos0) { 0 }
    let(:pos1) { 1 }
    it "returns a null Snippet with an empty snippet" do
      expect(described_class.from(node, pos0, pos1)).to be_an_instance_of(EPub::SnippetNullObject)
      expect(described_class.from(node, pos0, pos1).snippet).to eq ""
    end
  end
end
