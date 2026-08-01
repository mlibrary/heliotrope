describe("Control.Search", function () {
  var reader; var control;
  var options = { 
    region: 'top.toolbar.left',
    searchUrl: '/cozy-sun-bear/epub_search/mock.epub?q='
  };

  var getText = function(node) {
    var text = node.textContent;
    return text.replace(/^\s+/g, '').replace(/\s*$/g, '');
  };

  beforeEach(function() {
    reader = cozy.reader(document.createElement('div'), {
      engine: 'mock',
      href: 'mock.epub'
    });
  });

  it("can be added to an unloaded reader", function () {
    new cozy.Control.Search(options).addTo(reader);
  });

  describe("operating", function() {
    beforeEach(function() {
      control = new cozy.Control.Search(options).addTo(reader);
      reader.start(function() {

      })
    })

    it("handles empty results", function () {
      control.searchString = 'paratext';
      control._data = { q: control.searchString, search_results: [] };
      control._buildResults();
      var article = control._article;
      expect(getText(article)).to.contain('No results found');
    });

    it("handles results", function () {
      control.searchString = 'paratext';
      control._data = {"q":"paratexts","search_results":[{"cfi":"/6/6[Title01]!/4/4/2,/1:34,/1:43","title":"Title Page","snippet":"...Promos, Spoilers, and Other Media Paratexts..."},{"cfi":"/6/8[Copyright01]!/4/16,/1:57,/1:66","title":"Copyright","snippet":"...ld separately : promos, spoilers, and other media paratexts / Jonathan Gray...."},{"cfi":"/6/12[Contents]!/4/8/2,/1:42,/1:51","title":"Contents","snippet":"...1  From Spoilers to Spinoffs: A Theory of Paratexts..."},{"cfi":"/6/12[Contents]!/4/16/2,/1:41,/1:50","title":"Contents","snippet":"...5  Spoiled and Mashed Up: Viewer-Created Paratexts..."},{"cfi":"/6/12[Contents]!/4/20/2,/1:42,/1:51","title":"Contents","snippet":"...Conclusion: “In the DNA”: Creating across Paratexts..."},{"cfi":"/6/14[Acknowledgement]!/4/4,/1:406,/1:415","title":"Acknowledgments","snippet":"...nsiderably refined and advanced my thinking about paratexts. With this in mind, I offer thanks to a small band ..."},{"cfi":"/6/14[Acknowledgement]!/4/4,/1:525,/1:534","title":"Acknowledgments","snippet":"...ds who never seem to tire of discussing texts and paratexts with me, and who have shared their own thoughts on ..."},{"cfi":"/6/16[Introduction]!/4/20/2,/1:10,/1:19","title":"Introduction: Film, Television, and Off-Screen Studies","snippet":"...Of Texts, Paratexts, and Peripherals: A Word on Terminology..."},{"cfi":"/6/16[Introduction]!/4/28/2,/1:0,/1:9","title":"Introduction: Film, Television, and Off-Screen Studies","snippet":"...eems appropriate, I will more frequently refer to paratexts and to ..."},{"cfi":"/6/16[Introduction]!/4/28,/11:204,/11:213","title":"Introduction: Film, Television, and Off-Screen Studies","snippet":"...cally part of—the text. The book’s thesis is that paratexts are not simply add-ons, spinoffs, and also-rans: th..."},{"cfi":"/6/16[Introduction]!/4/30,/1:0,/1:9","title":"Introduction: Film, Television, and Off-Screen Studies","snippet":"...Paratexts often take a tangible form, as with posters, videog..."},{"cfi":"/6/16[Introduction]!/4/32,/5:147,/5:156","title":"Introduction: Film, Television, and Off-Screen Studies","snippet":"... television program “the text” or, in relation to paratexts, “the source text.” To use the word “text” in such ..."},{"cfi":"/6/16[Introduction]!/4/32,/11:198,/11:207","title":"Introduction: Film, Television, and Off-Screen Studies","snippet":"...d evaluations of this world will always rely upon paratexts too. Hence, since my book argues that a film or pro..."},{"cfi":"/6/16[Introduction]!/4/32,/11:439,/11:448","title":"Introduction: Film, Television, and Off-Screen Studies","snippet":"...ies,” I call for a screen studies that focuses on paratexts’ constitutive role in creating textuality, rather t..."},{"cfi":"/6/16[Introduction]!/4/32,/11:522,/11:531","title":"Introduction: Film, Television, and Off-Screen Studies","snippet":"...reating textuality, rather than simply consigning paratexts to the also-ran category or considering their impor..."}]};
      control._buildResults();
      var article = control._article;
      var num_links = article.querySelectorAll("a[href]").length;
      expect(num_links).to.eql(control._data.search_results.length);
    });

    it("canceling prevents the modal from opening", function () {
      // stub submitQuery?
      // introduce delay?
    });

  })

});

