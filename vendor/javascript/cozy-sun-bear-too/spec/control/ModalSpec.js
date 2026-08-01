describe("Modal", function () {
  var reader;
  var options = { region: 'top.toolbar.left' };

  function simulateClick(el) {
  	if (document.createEvent) {
  		var e = document.createEvent('MouseEvents');
  		e.initMouseEvent('click', true, true, window,
  				0, 0, 0, 0, 0, false, false, false, false, 0, null);
  		return el.dispatchEvent(e);
  	} else if (el.fireEvent) {
  		return el.fireEvent('onclick');
  	}
  }

  function simulateKeypress(character) {
  	// if (document.createEvent) {
  	// 	var evt = document.createEvent('KeyboardEvent');
  	// 	(evt.initKeyEvent || evt.initKeyboardEvent)("keypress", true, true, window,
  	// 	                    0, 0, 0, 0,
  	// 	                    0, character.charCodeAt(0))
  	// }
    var evt = new Event("keypress");
    evt.key = character;
    evt.keyCode = evt.key.charCodeAt(0);
    evt.which = evt.keyCode;
    evt.altKey = false;
    evt.ctrlKey = false;
    evt.shiftKey = false;
    evt.metaKey = false;
    evt.bubbles = true;
    document.dispatchEvent(evt);
  }

  beforeEach(function() {
    reader = cozy.reader(document.createElement('div'), {
      engine: 'mock',
      href: 'mock.epub'
    });    
  });

  it("basic modal can be created", function () {
  	var modal = reader.modal({
        region: 'left',
        title: 'Stage Left',
        template: '<p>Ahoy.</p>'
    })
  	expect(modal.modal.getAttribute('aria-hidden')).to.be('true');
  });

  describe("advanced behaviors", function() {
  	var modal;
  	var result;
  	beforeEach(function() {
  		modal = reader.modal({
  		        region: 'left',
  		        title: 'Stage Left',
  		        template: '<p><a href="#one">First Link</a></p><p><a href="#two">Second Link</a></p><p><a href="#three">Third Link</a></p>',
  		        actions: [
	  		        { label: 'Action 1', callback: function(event) { result = "Action 1" } },
	  		        { label: 'Action 2', callback: function(event) { result = "Action 2" }, close: true },
  		        ]
  		    })
  	});

  	it("is not dismissed clicking Action 1", function() {
      modal.callbacks.onShow = function() {
        var button = modal.container.querySelector("#action-" + modal._id + "-0");
        simulateClick(button);
        expect(result).to.be('Action 1');
        expect(modal.modal.getAttribute('aria-hidden')).to.be('false');
      };
      modal.showModal();  
  	})

  	it("is dismissed clicking Action 2", function() {
      modal.callbacks.onShow = function() {
        var button = modal.container.querySelector("#action-" + modal._id + "-1");
        simulateClick(button);
        expect(result).to.be('Action 2');
        expect(modal.modal.getAttribute('aria-hidden')).to.be('true');
      };
      modal.showModal();  
  	})

  	// setTimeout to allow modal to be opened and focus to shift?
  	it("the close button should have focus", function() {
      modal.callbacks.onShow = function() {
        var button = modal.container.querySelector("header .modal__close");
        expect(modal.modal.getAttribute('aria-hidden')).to.be('false');
      };
      modal.showModal();
  	})

  	it("tab should keep focus within modal", function() {
  		var tab = "\t";
      var is_ready = false;
      var focusable = null;
      modal.callbacks.onShow = function() {
        focusable = modal.getFocusableNodes();

        // // use the timeout to wait for document.activeElement to rest on the close button
        // setTimeout(function() {
        //   expect(modal.modal.getAttribute('aria-hidden')).to.be('false');
        //   expect(document.activeElement).to.be(focusable[0]);

        //   simulateKeypress(tab);
        //   expect(document.activeElement).to.be(focusable[1]);

        //   simulateKeypress(tab);
        //   expect(document.activeElement).to.be(focusable[2]);

        //   simulateKeypress(tab);
        //   expect(document.activeElement).to.be(focusable[3]);

        //   simulateKeypress(tab);
        //   expect(document.activeElement).to.be(focusable[4]);

        //   simulateKeypress(tab);
        //   expect(document.activeElement).to.be(focusable[0]);
        // }, 0);
      };
      modal.showModal();
  	})

  })

  describe("event behaviors", function() {
    var modal;
    var result = 'NOP';
    beforeEach(function() {
      modal = reader.modal({
              region: 'left',
              title: 'Stage Left',
              template: '<p><a href="#one"><span>First</span> Link</a></p><p><a href="#two">Second Link</a></p><p><a href="#three">Third Link</a></p><p><span id="notalink">Click here.</span></p>',
              actions: [
                { label: 'Action 1', callback: function(event) { result = "Action 1" } },
                { label: 'Action 2', callback: function(event) { result = "Action 2" }, close: true },
              ]
          })

      modal.on('click', 'a[href="#one"]', function(modal, target) {
        result = 'Link 1';
      })

      modal.on('click', 'a[href="#two"]', function(modal, target) {
        result = 'Link 2';
        return true;
      })

      modal.on('click', 'span#notalink', function(modal, target) {
        result = 'NOT REACHED';
        return true;
      })

    });

    it("is not dismissed clicking Link 1", function() {
      modal.callbacks.onShow = function() {
        var link = modal.container.querySelector("a[href='#one']");
        simulateClick(link);
        expect(result).to.be('Link 1');
        expect(modal.modal.getAttribute('aria-hidden')).to.be('false');

        var span = modal.container.querySelector("a[href='#one'] span");
        simulateClick(span);
        expect(result).to.be('Link 1');
        expect(modal.modal.getAttribute('aria-hidden')).to.be('false');
      };
      modal.showModal();  
    })

    it("is dismissed clicking Link 2", function() {
      modal.callbacks.onShow = function() {
        var link = modal.container.querySelector("a[href='#two']");
        simulateClick(link);
        expect(result).to.be('Link 2');
        expect(modal.modal.getAttribute('aria-hidden')).to.be('true');
      };
      modal.showModal();  
    })

    it("is dismissed clicking the close button", function() {
      modal.callbacks.onShow = function() {
        var button = modal.container.querySelector("button.modal__close");
        simulateClick(button);
        expect(modal.modal.getAttribute('aria-hidden')).to.be('true');
      };
      modal.showModal();  
    })

    it("is is ignored", function() {
      // reader.on('modal-opened', function() {
      //   var span = modal.container.querySelector("#notalink");
      //   simulateClick(span);
      //   expect(modal.modal.getAttribute('aria-hidden')).to.be('true');
      // })
      modal.callbacks.onShow = function() {
        var span = modal.container.querySelector("#notalink");
        simulateClick(span);
        expect(modal.modal.getAttribute('aria-hidden')).to.be('false');
      };

      modal.showModal();  
    })

  })


});