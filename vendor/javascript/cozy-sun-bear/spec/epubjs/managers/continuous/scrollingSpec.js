describe("Control.BibliographicInformation", function () {

  var reader;

  it("will will open a book in scrolled-doc", function(done) {
    this.timeout(100000);
    var div = document.createElement('div');
    document.body.appendChild(div);
    div.style.width = '100vw';
    div.style.height = '100vh';
    reader = cozy.reader(div, {
      href: '/base/spec/fixtures/moby-dick/',
      flow: 'scrolled-doc'
    })

    reader.start(function() {
      console.log("AHOY READER");
      expect(reader._rendition).to.not.be(null);
      expect(reader._rendition.manager).to.not.be(null);
      expect(reader._rendition.manager.constructor.name).to.be('ScrollingContinuousViewManager');
      done();
    })
  })

});