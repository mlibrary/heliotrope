describe("Control.Contents", function () {
  var reader; var control;
  var options = { region: 'top.toolbar.left' };

  describe("no skip link", function() {
    beforeEach(function() {
      reader = cozy.reader(document.createElement('div'), {
        engine: 'mock',
        href: 'mock.epub',
      });

      control = new cozy.Control.Contents(options).addTo(reader);
      reader.start(function() {
        happen.click(control._control);
      });
    });

    it("contents panel will be constructed", function () {
      var div = control._modal._container;
      var node = div.querySelectorAll("a");
      expect(node.length).not.to.eql(0);
    });

    it("skip link WILL NOT be created", function () {
      // expect(document.getElementById(control._id)).to.be(null);
      var link = document.querySelector("a[href='#action-" + control._id + "']");
      expect(link).to.be(null);
    });
  })

  describe("skip link", function() {
    var skip_div;

    beforeEach(function() {
      var skip_div = document.createElement('div');
      skip_div.setAttribute('class', 'skip');
      document.body.appendChild(skip_div);

      reader = cozy.reader(document.createElement('div'), {
        engine: 'mock',
        href: 'mock.epub',
      });

      control = new cozy.Control.Contents({ region: options.region, skipLink: '.skip'}).addTo(reader);
      reader.start(function() {
        happen.click(control._control);
      });
    });

    it("skip link WILL be created", function () {
      var link = document.querySelector("a[href='#action-" + control._id + "']");
      expect(link).not.to.be(null);
    });

  })

});

