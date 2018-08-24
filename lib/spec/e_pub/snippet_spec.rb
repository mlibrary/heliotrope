# frozen_string_literal: false

RSpec.describe EPub::Snippet do
  let(:chapter) do
    <<-EOT
    <html>
      <head>
        <title>Stuff about Things</title>
      </head>
      <body>
      <p>The one grand stage. A long rude ponderous table. At all times except when whales were alongside. Securely lashed athwartships against the rear of the Try-works.</p>
      <p>There are sentences in this paragraph about things. And more things. And this *thing*. And other things. But nothing about stuff.</p>
      <p>First part of the sentence <span>ends. And then a second part <i class="thing">inside a third ends.</i> And this part</span> is outside another part. Another tiny sentence. <b>That's all.</b></p>
      <p class="indent">Lending the production of three films considerably more gravitas and mythic resonance, the DVDs' producers paint a picture of multiple other fellowships, innocent and struggling hobbits, charismatic rangers, and sage wizards. Most notably, the cast often transpose their filmic roles onto their own personages, or have the act performed by others. For instance, Orlando Bloom talks of what a privilege it was to come out of drama school and work with the likes of Ian McKellen, who, he notes, brought his "wise old wizard"; ways to the cast, becoming a real-life Gandalf. Likewise, numerous cast and crew members discuss Viggo Mortensen's charisma and leadership as if he was his character, the ranger who becomes king, Aragorn. The stuntmen claim that his hard work and dedication on the gruelling Helm's Deep set inspired them. We learn of Mortensen's personal pull in convincing cast and crew alike to camp out the night before a dawn shoot. Colleagues talk of him as an earthy, nature-loving man. And Second Unit Director John Mahaffi even declares, "If I was going into battle and I needed someone to be on my right shoulder, it would be Viggo." Meanwhile, Dominic Monaghan and Billy Boyd provide much of the DVDs' comic relief, reprising their roles as the cheeky, prankster hobbits. In the cast commentary, they constantly toy with the film's register of reality, joking that a dreary, rocky scene looks just like Manchester, for instance, or that the film's huge dragon-like Balrog never bought a round when at the pub with them. Whereas most of the fifteen cast members contributing to the commentary were recorded individually, Monaghan and Boyd are recorded together, hence allowing their back-and-forth banter. Interestingly, too, while Elijah Wood and Sean Astin were recorded with them for the <i>Fellowship of the Ring</i> commentary, and similarly joked <span epub:type="pagebreak" id="page_93" title="93"/>around as carefree hobbits, the <i>Two Towers</i> commentary separates them from Monaghan and Boyd. Paralleling Frodo and Sam's path into darkness, Wood and Astin's commentary takes on a more pensive, reflective nature.</p>
      <p>Here is a <b>sentence</b>. The word <i class="stuff">searched</i> is in the last sentence.</p>
      <p>A one line paragraph.</p>
      <p>When the text contains a link to a footnote<sup><a href="#">23</a></sup>, it is removed</p>
      <blockqoute class="poem">
        I am a poem.
        About not using paragraphs.
        Aren't I annoying.
      </blockqoute>
      <p>The End.</p>
      </body>
    </html>
    EOT
  end

  let(:doc) { Nokogiri::XML(chapter) }

  before do
    doc.remove_namespaces!
  end

  describe "#parse_sentences" do
    let(:node) { doc.xpath("//body/p")[2].children[0] }
    let(:pos0) { 80 }
    let(:pos1) { 84 }
    let(:text) { "There are sentences in this paragraph about things. And more things. {{{HIT}}}And this *thing*. And other things. But nothing about stuff." }

    it "returns the correct *things* with surrounding sentences from a paragraph" do
      expect(described_class.from(node, pos0, pos1).parse_sentences(text)).to eq ['And more things.', 'And this *thing*.', 'And other things.']
    end
  end

  describe "#parent_paragraph" do
    let(:node) { doc.xpath("//body/p/span/i[@class='thing']").children[0] }
    let(:pos0) { 9 } # the word 'third'
    let(:pos1) { 13 }

    it "returns a node's parent paragraph" do
      para = described_class.from(node, pos0, pos1).parent_paragraph(node)
      expect(para.name).to eq 'p'
      expect(para.text).to eq "First part of the sentence ends. And then a second part inside a third ends. And this part is outside another part. Another tiny sentence. That's all."
    end
  end

  describe "#parent_paragraph" do
    let(:node) { doc.xpath("//body/blockqoute[@class='poem']").children[0] }
    let(:pos0) { 78 } # the word "annoying"
    let(:pos1) { 85 }

    it "returns 'body' since this poem has no parent paragraph" do
      para = described_class.from(node, pos0, pos1).parent_paragraph(node)
      expect(para.name).to eq 'body'
    end
  end

  describe "#parse_fragments" do
    subject { described_class.from(node, pos0, pos1) }

    let(:node) { doc.xpath("//body/p/span/i[@class='thing']").children[0] }
    let(:pos0) { 9 } # the word 'third'
    let(:pos1) { 13 }

    it "returns a paragraph with a {{{HIT}}} in it" do
      # Yeah, this is not great. But we need to identify which sentence has the search term in it without relying on the markup
      expect(subject.parse_fragments(subject.parent_paragraph(subject.node))). to eq "First part of the sentence ends. And then a second part inside a{{{HIT}}} third ends. And this part is outside another part. Another tiny sentence. That's all."
    end
  end

  describe "#parse_fragments" do
    subject { described_class.from(node, pos0, pos1) }

    let(:node) { doc.xpath("//body/p")[6].children[0] }
    let(:pos0) { 9 }
    let(:pos1) { 12 }

    it "when the text contains a link to a footnote, it is removed" do
      expect(subject.parse_fragments(subject.parent_paragraph(subject.node))).to eq "When the{{{HIT}}} text contains a link to a footnote, it is removed"
    end
  end

  describe "#parse_sentences" do
    subject { described_class.from(node, pos0, pos1) }

    let(:node) { doc.xpath("//body/p/span/i[@class='thing']").children[0] }
    let(:pos0) { 9 } # the word 'third'
    let(:pos1) { 13 }

    it "returns the correct sentence including the original search term and including additional surrounding context sentences from complex nested markup" do
      expect(subject.snippet).to eq "First part of the sentence ends. And then a second part inside a third ends. And this part is outside another part."
    end
  end

  describe "#determine_size" do
    subject { described_class.from(node, pos0, pos1) }
    # For these tests these don't matter, we just need a valid object...

    let(:node) { doc.xpath("//p")[5].children[0] }
    let(:pos0) { 11 }
    let(:pos1) { 19 }

    context "with a single sentence" do
      let(:sentences) { ["A sentence."] }

      it "returns the sentence" do
        expect(subject.determine_size(sentences, 0)).to eq sentences
      end
    end

    context "with 3 sentences but the hit sentence is long" do
      let(:sentences) do
        ['First sentence.',
         'A very long and descriptive hit sentence all about the trails and tribulations of daily life complete with informative diagrams.',
         'A last sentence.']
      end

      it "returns only the hit sentence" do
        expect(subject.determine_size(sentences, 1)).to eq [sentences[1]]
      end
    end

    context "with 2 sentences but the hit sentence is long" do
      let(:sentences) do
        ['First sentence.',
         'A very long and descriptive hit sentence all about the trails and tribulations of daily life complete with informative diagrams.']
      end

      it "returns only the hit sentence" do
        expect(subject.determine_size(sentences, 1)).to eq [sentences[1]]
      end
    end

    context "with 2 short sentences with the hit as the last sentence" do
      let(:sentences) { ['First sentence.', 'Hit sentence.'] }

      it "returns the first and hit sentences in the right order" do
        expect(subject.determine_size(sentences, 1)).to eq sentences
      end
    end

    context "with 2 short sentences with the hit as the first sentence" do
      let(:sentences) { ['Hit sentence.', 'Last sentence.'] }

      it "returns the hit and last sentences in the right order" do
        expect(subject.determine_size(sentences, 0)).to eq sentences
      end
    end

    context "with 3 short sentences" do
      let(:sentences) { ['First sentence.', 'Hit sentence.', 'Last sentence'] }

      it "returns all three sentences" do
        expect(subject.determine_size(sentences, 1)).to eq sentences
      end
    end
  end

  describe "snippet for 'whales'" do
    let(:node) { doc.xpath("//body/p").first.children[0] }
    let(:pos0) { 76 }
    let(:pos1) { 81 }

    it "creates the snippit" do
      expect(described_class.from(node, pos0, pos1).snippet).to eq "A long rude ponderous table. At all times except when whales were alongside. Securely lashed athwartships against the rear of the Try-works."
    end
  end

  describe "snippet for 'carefree hobbits' with long sentences" do
    let(:node) { doc.xpath("//body/p")[3].children[4] }
    let(:pos0) { 10 }
    let(:pos1) { 26 }

    it "creates the snippet (which is only the one long sentence)" do
      expect(described_class.from(node, pos0, pos1).snippet).to eq "Interestingly, too, while Elijah Wood and Sean Astin were recorded with them for the Fellowship of the Ring commentary, and similarly joked around as carefree hobbits, the Two Towers commentary separates them from Monaghan and Boyd."
    end
  end

  describe "snippet for 'searched' which is in the last sentence of a 2 sentence paragraph" do
    let(:node) { doc.xpath("//p/i[@class='stuff']").children[0] }
    let(:pos0) { 0 }
    let(:pos1) { 7 }

    it "creates the two sentence snippet" do
      expect(described_class.from(node, pos0, pos1).snippet).to eq "Here is a sentence. The word searched is in the last sentence."
    end
  end

  describe "snippet for 'annoying' in a blockqoute with no parent paragraph" do
    subject { described_class.from(node, pos0, pos1).snippet }

    let(:node) { doc.xpath("//body/blockqoute[@class='poem']").children[0] }
    let(:pos0) { 78 } # the word "annoying"
    let(:pos1) { 85 }

    it "creates the snippet (which includes the first line of the next paragraph)" do
      expect(subject).to eq "About not using paragraphs. Aren't I annoying. The End."
    end
  end

  describe "snippet for 'A one line paragraph'" do
    subject { described_class.from(node, pos0, pos1).snippet }

    let(:node) { doc.xpath("//p")[5].children[0] }
    let(:pos0) { 11 }
    let(:pos1) { 19 }

    it "creates the snippet" do
      expect(subject).to eq 'A one line paragraph.'
    end
  end

  describe "with a null node" do
    subject { described_class.from(node, pos0, pos1) }

    let(:node) { nil }
    let(:pos0) { 0 }
    let(:pos1) { 1 }

    it "returns a null Snippet with an empty snippet" do
      expect(subject).to be_an_instance_of(EPub::SnippetNullObject)
      expect(subject.snippet).to eq ""
      expect(subject.parse_fragments).to eq ""
      expect(subject.parent_paragraph.name).to eq "p"
      expect(subject.parent_paragraph.text).to eq ""
    end
  end
end
