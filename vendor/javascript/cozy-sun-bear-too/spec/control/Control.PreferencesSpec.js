describe("Control.Preferences", function () {
  var reader; var control;
  var options = { 
    region: 'top.toolbar.right'
  };

  var getText = function(node) {
    var text = node.textContent;
    return text.replace(/^\s+/g, '').replace(/\s*$/g, '');
  };

  it("can be added to an unloaded reader", function () {
  	reader = cozy.reader(document.createElement('div'), {
  	  engine: 'mock',
  	  href: 'mock.epub'
  	});
    control = new cozy.Control.Preferences(options).addTo(reader);
    expect(control).not.to.be(null);
  });

  describe("builds preferences", function() {
    beforeEach(function() {
      control = new cozy.Control.Preferences(options).addTo(reader);
      reader.start(function() {
      	happen.click(control._control);
      })
    })

    it("sets up the preferences panel", function () {
    	var fieldsets = control._modal._container.querySelectorAll('fieldset');
    	expect(fieldsets.length).not.to.eql(0);
    });
  })

  describe("custom preferences", function() {
    beforeEach(function() {
      control = new cozy.Control.Preferences({
      	region: 'top.toolbar.right',
      	fields: [
	      	{
	      	    label: 'Custom Mode',
	      	    name: 'custom-mode',
	      	    inputs: [
	      	        { value: 'off', label: 'Off' },
	      	        { value: 'on', label: 'On'}
	      	    ],
	      	    value: 'off',
	      	    callback: function(value) {
	      	        control._custom = value;
	      	    },
	      	    hint: 'How to use this field.'
	      	}      		
      	]
      }).addTo(reader);
      reader.start(function() {
      	happen.click(control._control);
      })
    })

    it("has custom fields", function () {
    	var fieldset = control._modal._container.querySelector('fieldset.custom-field');
    	expect(fieldset).not.to.be(null);
    });

    it("invokes the callback on save", function() {
    	var fieldset = control._modal._container.querySelector('fieldset.custom-field');
    	var input = fieldset.querySelector("input:not(:checked)");
    	input.checked = true;
    	var event = { preventDefault: function() { }};
      control.initializeForm();
    	control.updatePreferences(event);
    	expect(control._custom).to.eql(input.value);
    })
  })

});

