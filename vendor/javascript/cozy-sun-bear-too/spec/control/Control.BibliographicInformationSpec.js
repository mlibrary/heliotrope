describe("Control.BibliographicInformation", function () {
  var reader; var control;
  var options = { region: 'top.toolbar.left' };

  var selector = function(key) {
    return "dd.cozy-bib-info-value-" + key;
  };

  describe("it can work as expected", function() {
    beforeEach(function() {
      reader = cozy.reader(document.createElement('div'), {
        engine: 'mock',
        href: 'mock.epub',
        metadata: {
          doi: 'https://doi.org/10.0000/cozy.0000'
        }
      });
      control = new cozy.Control.BibliographicInformation(options).addTo(reader);
      reader.start(function() {
        happen.click(control._control);
      });
    });

    it("title should be title", function() {
      var container = control._modal._container;
      var key; var expr; var node;

      key = 'title';
      expr = selector(key);
      node = container.querySelector(expr);
      expect(node).to.not.be(null);
      expect(node.innerText).to.eql(reader.metadata[key]);
    })

    it("creator should be creator", function() {
      var container = control._modal._container;
      var key; var expr; var node;

      key = 'creator';
      expr = selector(key);
      node = container.querySelector(expr);
      expect(node).to.not.be(null);
      expect(node.innerText).to.eql(reader.metadata[key]);
    })

    it("doi should be doi", function() {
      var container = control._modal._container;
      var key; var expr; var node;

      key = 'doi';
      expr = selector(key);
      node = container.querySelector(expr);
      expect(node).to.not.be(null);
      expect(node.innerText).to.eql(reader.metadata[key]);
    })

    it("pubdate should be abbreviated", function() {

      var container = control._modal._container;
      var key; var expr; var node;

      key = 'pubdate';
      expr = selector(key);
      node = container.querySelector(expr);
      expect(node).to.not.be(null);
      expect(node.innerText).to.not.eql(reader.metadata[key]);
      expect(node.innerText).to.eql("2017");
    })
  })


  describe("more date fun", function() {
    it("it can deal with MM-DD-YYYY", function() {
      reader = cozy.reader(document.createElement('div'), {
        engine: 'mock',
        href: 'mock.epub',
        metadata: {
          doi: 'https://doi.org/10.0000/cozy.0000',
          pubdate: '01-01-2015'
        }
      });
      control = new cozy.Control.BibliographicInformation(options).addTo(reader);
      reader.start(function() {
        happen.click(control._control);
      });

      var container = control._modal._container;
      var key; var expr; var node;

      key = 'pubdate';
      expr = selector(key);
      node = container.querySelector(expr);
      expect(node).to.not.be(null);
      expect(node.innerText).to.eql("2015");
    })

    it("it can deal with YYYY", function() {
      reader = cozy.reader(document.createElement('div'), {
        engine: 'mock',
        href: 'mock.epub',
        metadata: {
          doi: 'https://doi.org/10.0000/cozy.0000',
          pubdate: '1998'
        }
      });
      control = new cozy.Control.BibliographicInformation(options).addTo(reader);
      reader.start(function() {
        happen.click(control._control);
      });

      var container = control._modal._container;
      var key; var expr; var node;

      key = 'pubdate';
      expr = selector(key);
      node = container.querySelector(expr);
      expect(node).to.not.be(null);
      expect(node.innerText).to.eql("1998");
    })
  })

});

