# frozen_string_literal: false

RSpec.describe EPub::Snippet do
  let(:markup) do
  <<-EOT
<!DOCTYPE html>
<html lang="en">
<head><title>I Am The Horrible Document That Lives In The Repository.</title></head>
<body>
<section>
<h1>I am the horrible document.</h1>
<p>I have many horrible things in me and you have no hope. There are footnotes.<a class="note" href="#">001</a>
 And then things that are <a class="marquee" href="#">not footnotes</a> and you can't see them and you despair and
 there's a very long sentence with: words, more words, more words, more words, and still more words to make you sad;
 yet still it's not long enough and you are all the way stood up, all the way confused, all the way overalls and no ideas.
 Sometimes there <i>will be</i> just <a href="#">kind</a> of <b>random <i>marked-up <u>bits </u></i></b> and then
 I will <span class="sweet-sweet-release">strike</span> with the new kind of
 endnote!<sup><a href="#" class="enref">12</a></sup>Also   random     whitespace  .<a class="note" href="#">17</a>
 You have no chance against me.</p>
<p>Sneaky tiny paragraph!</p>
<p>And another! Because</p>
<p></p> <!-- LOL -->
<p>all fixed-width are like this and it brings</p>
<p>your suffering. And then I</p>
<p>make a fight between yourself</p>
<p>and your sad parsing and</p>
<p>I am victory.</p>
<p>Seriously</p><p>though</p><p>this</p><p>exists</p><p>and</p><p>you</p><p>can't</p><p>fix</p><p>it.</p>
<article>
<h3>You will never be well again.</h3>
<p class="p-tag-that-never-closes-but-is-somehow-valid">
  My markup is the worst markup and you have it. You cannot make a snippet out <a href="#">of <b>this mess</b></a>, it is
  not possible. Unfathomable!<a class="weird-name-note" href="#">42</a> I make it
  times <a class="unity-su-number" data-uid="999">999</a> terrible.
  <div class="unrelated-callout-thing">
    <h3>Were you aware?</h3>
    <p>I undo all of your doing!<a class="note" href="#">7(b)</a></p>
  </div>
  More words go here, to make your life worse.
</article>
<p class="sentence-terminator">
  Find this search. Term. You. Can't.
</p>
<p class="impossibly-long-word">
  Donaudampfschiffahrtselektrizitätenhauptbetriebswerkbauunterbeamtengesellschaft-Rindfleischetikettierungsüberwachungsaufgabenübertragungsgesetz
</p>
<div class="fig">
  <img alt="figure" src="#" />
  <p class="caption">
    <a id="#"><span class="fig-num">Fig. 10.6.</span></a>
    I don’t agree with property and never have. Here I come again!
  </p>
</div>
</section>
<footer>
  <ul>
    <li><button><img alt="ruined!" src="#" />I ruin your life!</button></li>
    <li>I make it <button><img id="terrible-list" alt="terrible!" src="#" />terrible!</button></li>
    <li><a href="https://www.shatnerchatner.com/p/i-am-the-horrible-goose-that-lives">Honk!</a></li>
  </ul>
</footer>
</body>
</html>
  EOT
end

  let(:doc) { Nokogiri::XML(markup) }
  before { doc.remove_namespaces! }

  describe "#snippet" do
    context "'ruin'" do
      let(:node) { doc.xpath('//footer/ul/li[1]').children[0].children[1] }
      # the word "ruin"
      # doc.xpath('//footer/ul/li[1]').children[0].children[1].text[2..5]
      let(:pos0) { 2 }
      let(:pos1) { 5 }

      it do
        expect(described_class.from(node, pos0, pos1).snippet).to eq "Here I come again! I ruin your life! I make it terrible!"
        # And *make sure* we didn't contaminate the DOM with the ugly "HIT" markings...
        expect(node).not_to match(/{{{HIT~/)
        expect(node).not_to match(/~HIT}}}/)
      end
    end

    context "'not possible'" do
      let(:node) { doc.xpath("//p[@class='p-tag-that-never-closes-but-is-somehow-valid']").children[2] }
      # the words "not possible"
      # doc.xpath("//p[@class='p-tag-that-never-closes-but-is-somehow-valid']").children[2].text[10..21]
      let(:pos0) { 10 }
      let(:pos1) { 21 }

      it do
        expect(described_class.from(node, pos0, pos1).snippet).to eq "is the worst markup and you have it. You cannot make a snippet out of this mess, it is not possible. Unfathomable!"
      end
    end

    context "'despair'" do
      let(:node) { doc.xpath("//section/p").first.children[4] }
      # the word "despair"
      # doc.xpath("//section/p").first.children[4].text[32..39]
      let(:pos0) { 32 }
      let(:pos1) { 38 }

      it do
        expect(described_class.from(node, pos0, pos1).snippet).to eq "and you can't see them and you despair and there's a very long sentence with: words, more words, more words, more words,"
      end
    end

    context "'overalls'" do
      let(:node) { doc.xpath("//section/p").first.children[4] }
      # the word "overalls"
      # doc.xpath("//section/p").first.children[4].text[261..268]
      let(:pos0) { 261 }
      let(:pos1) { 268 }

      it do
        expect(described_class.from(node, pos0, pos1).snippet).to eq "still it's not long enough and you are all the way stood up, all the way confused, all the way overalls and no ideas."
      end
    end

    context "'endnote'" do
      let(:node) { doc.xpath("//section/p").first.children[12] }
      # the word "endnote", the snippet should not include the actual endnote
      # doc.xpath("//section/p").first.children[12].text[23..30]
      let(:pos0) { 23 }
      let(:pos1) { 29 }

      it do
        expect(described_class.from(node, pos0, pos1).snippet).to eq "will be just kind of random marked-up bits and then I will strike with the new kind of endnote! Also random whitespace ." # TODO: pretty close! Whitespace before the period though
      end
    end

    context "'999'" do
      let(:node) { doc.xpath("//a[@class='unity-su-number']").children[0] }
      # the number '999' like in gabii where we have these Point of Interest numbers that people actually search for
      # doc.xpath("//a[@class='unity-su-number']").children[0].text[0..2]
      let(:pos0) { 0 }
      let(:pos1) { 2 }

      it do
        expect(described_class.from(node, pos0, pos1).snippet).to eq "Unfathomable! I make it times 999 terrible. Were you aware?"
      end
    end

    context "'10.6'" do
      let(:node) { doc.xpath("//span[@class='fig-num']").children[0] }
      # Same idea as above, searching for some kind of reference number, like '10.6' should work and have snippet context
      # doc.xpath("//span[@class='fig-num']").children[0].text[5..9]
      let(:pos0) { 5 }
      let(:pos1) { 9 }

      it do
        expect(described_class.from(node, pos0, pos1).snippet).to eq "Fig. 10.6. I don’t agree with property and never have. Here I come again!"
      end
    end

    context "'fixed-width'" do
      let(:node) { doc.xpath("//section/p").children[19] }
      # The text 'fixed-width', it's surrounding paragraphs should be used to give it context.
      # doc.xpath("//section/p").children[19].text[4..14]
      let(:pos0) { 4 }
      let(:pos1) { 14 }

      it do
        expect(described_class.from(node, pos0, pos1).snippet).to eq "And another! Because all fixed-width are like this and it brings your suffering. And then I make a fight between"
      end
    end

    context "'exists'" do
      let(:node) { doc.xpath("//section/p").children[27] }
      # The word 'exists'
      # These strung together paragraphs are real things in HEB that I think are bad markup.
      # The result will be words smushed together because there are no spaces between the words and
      # no spaces/newlines between the <p> tags. I don't know how to fix this.
      # doc.xpath("//section/p").children[25].text[0..5]
      let(:pos0) { 0 }
      let(:pos1) { 5 }

      it do
        expect(described_class.from(node, pos0, pos1).snippet).to eq "yourself and your sad parsing and I am victory. Seriouslythoughthisexistsandyoucan'tfixit. You will never be well again."
      end
    end

    context "'Honk!'" do
      let(:node) { doc.xpath("//footer/ul/li")[2].children[0].children[0] }
      # The last word in the document.
      # doc.xpath("//footer/ul/li")[2].children[0].children[0].text[0..5]
      let(:pos0) { 0 }
      let(:pos1) { 5 }

      it do
        expect(described_class.from(node, pos0, pos1).snippet).to eq "I make it terrible! Honk! " # TODO: why the extra space?
      end
    end

    context "'Term. You.'" do
      let(:node) { doc.xpath("//p[@class='sentence-terminator']").children[0] }
      # More than one 'sentence' shouldn't crash anything
      # doc.xpath("//p[@class='sentence-terminator']").children[0].text[23..32]
      let(:pos0) { 21 }
      let(:pos1) { 30 }

      it do
        # TODO: This isn't ideal, it's really short. But it doesn't break anything.
        expect(described_class.from(node, pos0, pos1).snippet).to eq "Find this search. Term. You."
      end
    end

    context "a part of a impossibly long word, 'engesellschaft'" do
      let(:node) { doc.xpath("//p[@class='impossibly-long-word']").children[0] }
      # "association of subordinate officials of the head office management of the Danube steamboat electrical services"
      # -
      # "beef labeling regulation and delegation of supervision law."
      # in German. Shouldn't break anything.
      # This is a silly example, but really bad OCR might not be
      # doc.xpath("//p[@class='impossibly-long-word']").children[0].text[68..81]
      let(:pos0) { 68 }
      let(:pos1) { 81 }

      it do
        expect(described_class.from(node, pos0, pos1).snippet).to eq "engesellschaft-Rindfleischetikettierungsüberwachungsaufgabenübertragungsgesetz"
      end
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
    end
  end
end
