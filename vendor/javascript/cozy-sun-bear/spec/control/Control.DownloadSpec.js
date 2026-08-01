describe("Control.Download", function () {
  var reader;
  var options = { region: 'top.toolbar.left' };

  var download_epub_link = 'https://archive.org/download/greeklivesfrompl00plutuoft/greeklivesfrompl00plutuoft.epub';
  var download_pdf_link = 'https://archive.org/download/greeklivesfrompl00plutuoft/greeklivesfrompl00plutuoft.pdf';

  beforeEach(function() {
    reader = cozy.reader(document.createElement('div'), {
      engine: 'mock',
      href: 'mock.epub',
      download_links: [
          {
              format: 'EPUB',
              size: '22 MB',
              href: download_epub_link
          },
          {
              format: 'PDF',
              size: '12 MB',
              href: download_pdf_link
          }
        ]
    });    
  });

  it("can be added to an unloaded reader", function () {
    new cozy.Control.Download(options).addTo(reader);
  });

  it("can be added and use the download links via modal", function () {
    var control = new cozy.Control.Download(options).addTo(reader);
    reader.start(function() {
      happen.click(control._control);

      var possibles = 
        [
          [ 'EPUB', download_epub_link ],
          [ 'PDF', download_pdf_link ]
        ];

      for(var i in possibles) {
        var value = possibles[i][0];
        var test = possibles[i][1];

        control._configureDownloadForm(test);
        var form = control._form;

        expect(form.getAttribute("action")).to.be(test);
      }
    });


  });
});

