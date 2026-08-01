describe("Control.Citation", function () {
  var reader;
  var options = { region: 'top.toolbar.left' };

  beforeEach(function() {
    reader = cozy.reader(document.createElement('div'), {
      engine: 'mock',
      href: 'mock.epub',
      metadata: {
        citations: [
          { format: 'MLA', text: "Mock, Alex. <em>The Mock Life</em>. University Press, 2017." },
          { format: 'APA', text: "Mock, A. (2017). <em>The Mock Life</em>. Ann Arbor, MI: University Press." },
          { format: 'Chicago', text: "Mock, Alex. <em>The Mock Life</em>. Ann Arbor, MI: University Press, 2017." }
        ]
      }
    });
  });

  it("can be added to an unloaded reader", function () {
    new cozy.Control.Citation(options).addTo(reader);
  });

  describe("use the default metadata via modal", function() {
    beforeEach(function() {
      control = new cozy.Control.Citation(options).addTo(reader);
      reader.start(function() {
        happen.click(control._control);
      });
    })

    var format; var test; var formatted;
    var possibles = {
      'MLA':  "Mock, Alex. <em>The Mock Life</em>. University Press, 2017.",
      'APA': "Mock, A. (2017). <em>The Mock Life</em>. Ann Arbor, MI: University Press.",
      'Chicago': "Mock, Alex. <em>The Mock Life</em>. Ann Arbor, MI: University Press, 2017."
    };

    it("should format MLA", function() {
      format = 'MLA';
      formatted = control._formatCitation(format);
      expect(formatted).to.eql(possibles[format]);
    })

    it("should format APA", function() {
      format = 'APA';
      formatted = control._formatCitation(format);
      expect(formatted).to.eql(possibles[format]);
    })

    it("should format Chicago", function() {
      format = 'Chicago';
      formatted = control._formatCitation(format);
      expect(formatted).to.eql(possibles[format]);
    })


  })
});

