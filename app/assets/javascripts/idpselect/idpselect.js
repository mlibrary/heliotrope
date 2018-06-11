function IdPSelectUI() {
    //
    // module locals
    //
    var idpData;
    var base64chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=';
    var idpSelectDiv;
    var lang;
    var majorLang;
    var defaultLang;
    var langBundle;
    var defaultLangBundle;
    var defaultLogo;
    var defaultLogoWidth;
    var defaultLogoHeight;
    var minWidth;
    var minHeight;
    var maxWidth;
    var maxHeight;
    var bestRatio;
    var doNotCollapse;

    //
    // Parameters passed into our closure
    //
    var preferredIdP;
    var maxPreferredIdPs;
    var helpURL;
    var ie6Hack;
    var samlIdPCookieTTL;
    var maxIdPCharsDropDown;
    var maxIdPCharsButton;
    var maxIdPCharsAltTxt;
    var alwaysShow;
    var maxResults;
    var ignoreKeywords;
    var showListFirst;
    var noWriteCookie;
    var ignoreURLParams;

    var autoFollowCookie;
    var autoFollowCookieTTLs;

    //
    // The cookie contents
    //
    var userSelectedIdPs;
    //
    // Anchors used inside autofunctions
    //
    var idpEntryDiv;
    var idpListDiv;
    var idpSelect;
    var listButton;
    
    //
    // local configuration
    //
    var idPrefix = 'idpSelect';
    var classPrefix = 'IdPSelect';
    var dropDownControl;

    //
    // DS protocol configuration
    //
    var returnString = '';
    var returnBase='';
    var returnParms= [];
    var returnIDParam = 'entityID';

    // *************************************
    // Public functions
    // *************************************
    
    /**
       Draws the IdP Selector UI on the screen.  This is the main
       method for the IdPSelectUI class.
    */
    this.draw = function(parms){
        idpSelectDiv = document.getElementById(parms.insertAtDiv);
        if(!idpSelectDiv){
            fatal(getLocalizedMessage('fatal.divMissing'));
            return;
        }

        if (!setupLocals(parms)) {
            return;
        }

        //
        // Quick test for auto-dispatch
        //
        if ((null != autoFollowCookie) && (null != getCookieCalled( autoFollowCookie ))) {

            var prefs = retrieveUserSelectedIdPs();
            if (prefs.length != 0) {
                var retString = returnIDParam + '=' + encodeURIComponent(prefs[0]);
                //
                // Compose up the URL
                //
                if (returnString.indexOf('?') == -1) {
                    retString = '?' + retString;
                } else {
                    retString = '&' + retString;
                }
                //
                // Go there
                //
                dispatchTo(idpSelectDiv, returnString + retString);
                return;
            }
        }

        if (!load(parms.dataSource)) {
            return;
        }
        deDupe();
        stripHidden(parms.hiddenIdPs);

        idpData.sort(function(a,b) {return getLocalizedName(a).localeCompare(getLocalizedName(b));});
        
        var idpSelector = buildIdPSelector();
        idpSelectDiv.appendChild(idpSelector);
        dropDownControl.draw(parms.setFocusTextBox);
    } ;
    
    // *************************************
    // Private functions
    //
    // Data Manipulation
    //
    // *************************************

    /**
       Copies the "parameters" in the function into namesspace local
       variables.  This means most of the work is done outside the
       IdPSelectUI object
    */

    var setupLocals = function (paramsSupplied) {
        //
        // Copy parameters in
        //
        var suppliedEntityId;

        preferredIdP = paramsSupplied.preferredIdP;
        maxPreferredIdPs = paramsSupplied.maxPreferredIdPs;
        helpURL = paramsSupplied.helpURL;
        ie6Hack = paramsSupplied.ie6Hack;
        samlIdPCookieTTL = paramsSupplied.samlIdPCookieTTL;
        alwaysShow = paramsSupplied.alwaysShow;
        maxResults = paramsSupplied.maxResults;
        ignoreKeywords = paramsSupplied.ignoreKeywords;
        if (paramsSupplied.showListFirst) {
            showListFirst = paramsSupplied.showListFirst;
        } else {
            showListFirst = false;
        }
        if (paramsSupplied.noWriteCookie) {
            noWriteCookie = paramsSupplied.noWriteCookie;
        } else {
            noWriteCookie = false;
        }
        if (paramsSupplied.ignoreURLParams) {
            ignoreURLParams = paramsSupplied.ignoreURLParams;
        } else {
            ignoreURLParams = false;
        }

        defaultLogo = paramsSupplied.defaultLogo;
        defaultLogoWidth = paramsSupplied.defaultLogoWidth;
        defaultLogoHeight = paramsSupplied.defaultLogoHeight;
        minWidth = paramsSupplied.minWidth;
        minHeight = paramsSupplied.minHeight;
        maxWidth = paramsSupplied.maxWidth;
        maxHeight = paramsSupplied.maxHeight;
        bestRatio = paramsSupplied.bestRatio;
        if (null == paramsSupplied.doNotCollapse) { 
            doNotCollapse = true;
        } else {
            doNotCollapse = paramsSupplied.doNotCollapse;
        }
            
        maxIdPCharsButton = paramsSupplied.maxIdPCharsButton;
        maxIdPCharsDropDown = paramsSupplied.maxIdPCharsDropDown;
        maxIdPCharsAltTxt = paramsSupplied.maxIdPCharsAltTxt;

        autoFollowCookie = paramsSupplied.autoFollowCookie;
        autoFollowCookieTTLs = paramsSupplied.autoFollowCookieTTLs;

        var lang;

        if (typeof navigator == 'undefined') {
            lang = paramsSupplied.defaultLanguage;
        } else {
            lang = navigator.language || navigator.userLanguage || paramsSupplied.defaultLanguage;
        }
        lang = lang.toLowerCase();

        if (lang.indexOf('-') > 0) {
            majorLang = lang.substring(0, lang.indexOf('-'));
        }

        var providedLangs = new IdPSelectLanguages();

        defaultLang = paramsSupplied.defaultLanguage;

        if (typeof paramsSupplied.langBundles != 'undefined' && typeof paramsSupplied.langBundles[lang] != 'undefined') {
            langBundle = paramsSupplied.langBundles[lang];
        } else if (typeof providedLangs.langBundles[lang] != 'undefined') {
            langBundle = providedLangs.langBundles[lang];
        } else if (typeof majorLang != 'undefined') {
            if (typeof paramsSupplied.langBundles != 'undefined' && typeof paramsSupplied.langBundles[majorLang] != 'undefined') {
                langBundle = paramsSupplied.langBundles[majorLang];
            } else if (typeof providedLangs.langBundles[majorLang] != 'undefined') {
                langBundle = providedLangs.langBundles[majorLang];
            }
        }
        
        if (typeof paramsSupplied.langBundles != 'undefined' && typeof paramsSupplied.langBundles[paramsSupplied.defaultLanguage] != 'undefined') {
            defaultLangBundle = paramsSupplied.langBundles[paramsSupplied.defaultLanguage];
        } else {
            defaultLangBundle = providedLangs.langBundles[paramsSupplied.defaultLanguage];
        }

        //
        // Setup Language bundles
        //
        if (!defaultLangBundle) {
            fatal('No languages work');
            return false;
        }
        if (!langBundle) {
            debug('No language support for ' + lang);
            langBundle = defaultLangBundle;
        }

        if (paramsSupplied.testGUI) {
            //
            // no policing of parms
            //
            return true;
        }
        //
        // Now set up the return values from the URL
        //
        var policy = 'urn:oasis:names:tc:SAML:profiles:SSO:idpdiscovery-protocol:single';
        var i;
        var isPassive = false;
        var parms;
        var parmPair;
        var win = window;
        while (null !== win.parent && win !== win.parent) {
            win = win.parent;
        }
        var loc = win.location;
        var parmlist = loc.search;
        if (ignoreURLParams || null == parmlist || 0 == parmlist.length || parmlist.charAt(0) != '?') {

            if ((null == paramsSupplied.defaultReturn)&& !ignoreURLParams) {

                fatal(getLocalizedMessage('fatal.noparms'));
                return false;
            }
            //
            // No parameters, so just collect the defaults
            //
            suppliedEntityId  = paramsSupplied.myEntityID;
            returnString = paramsSupplied.defaultReturn;
            if (null != paramsSupplied.defaultReturnIDParam) {
                returnIDParam = paramsSupplied.defaultReturnIDParam;
            }
            
        } else {
            parmlist = parmlist.substring(1);

            //
            // protect against various hideousness by decoding. We re-encode just before we push
            //

            parms = parmlist.split('&');
            if (parms.length === 0) {

                fatal(getLocalizedMessage('fatal.noparms'));
                return false;
            }

            for (i = 0; i < parms.length; i++) {
                parmPair = parms[i].split('=');
                if (parmPair.length != 2) {
                    continue;
                }
                if (parmPair[0] == 'entityID') {
                    suppliedEntityId = decodeURIComponent(parmPair[1]);
                } else if (parmPair[0] == 'return') {
                    returnString = decodeURIComponent(parmPair[1]);
                } else if (parmPair[0] == 'returnIDParam') {
                    returnIDParam = decodeURIComponent(parmPair[1]);
                } else if (parmPair[0] == 'policy') {
                    policy = decodeURIComponent(parmPair[1]);
                } else if (parmPair[0] == 'isPassive') {
                    isPassive = (parmPair[1].toUpperCase() == "TRUE");
                }
            }
        }
        // Test protocol
        var allowableProtocols;
        if (null == paramsSupplied.allowableProtocols) {
            allowableProtocols = ["urn:oasis:names:tc:SAML:profiles:SSO:idpdiscovery-protocol:single"];
        } else {
            allowableProtocols = paramsSupplied.allowableProtocols;
        }

        var protocolOk = false;
        for (var i = 0 ; i < allowableProtocols.length; i++) {
            var protocol = allowableProtocols[i];
            if (policy == protocol) {
                protocolOk = true;
                break;
            }
        }

        if (!protocolOk) {
            fatal(getLocalizedMessage('fatal.wrongProtocol'));
            return false;
        }
        if (paramsSupplied.myEntityID !== null && paramsSupplied.myEntityID != suppliedEntityId) {
            fatal(getLocalizedMessage('fatal.wrongEntityId') + '"' + suppliedEntityId + '" != "' + paramsSupplied.myEntityID + '"');
            return false;
        }
        if (null === returnString || returnString.length === 0) {
            fatal(getLocalizedMessage('fatal.noReturnURL'));
            return false;
        }
        if (!validProtocol(returnString)) {
            fatal(getLocalizedMessage('fatal.badProtocol'));
            return false;
        }

        //
        // isPassive
        //
        if (isPassive) {
            var prefs = retrieveUserSelectedIdPs();
            var parentDiv = document.getElementById(parmsSupplied.insertAtDiv);
            if (prefs.length == 0) {
                //
                // no preference, go back
                //
                dispatchTo(parentDiv, returnString);
                return false;
            } else {
                var retString = returnIDParam + '=' + encodeURIComponent(prefs[0]);
                //
                // Compose up the URL
                //
                if (returnString.indexOf('?') == -1) {
                    retString = '?' + retString;
                } else {
                    retString = '&' + retString;
                }

                dispatchTo(parentDiv, returnString + retString);
                return false;
            }            
        }

        //
        // Now split up returnString
        //
        i = returnString.indexOf('?');
        if (i < 0) {
            returnBase = returnString;
            return true;
        }
        returnBase = returnString.substring(0, i);
        parmlist = returnString.substring(i+1);
        parms = parmlist.split('&');
        for (i = 0; i < parms.length; i++) {
            parmPair = parms[i].split('=');
            if (parmPair.length != 2) {
                continue;
            }
            parmPair[1] = decodeURIComponent(parmPair[1]);
            returnParms.push(parmPair);
        }
        return true;
    };

    /** Deduplicate by entityId */
    var deDupe = function() {
        var names = [];
        var j;
        for (j = 0; j < idpData.length; ) {
            var eid = getEntityId(idpData[j]);
            if (null == names[eid]) {
                names[eid] = eid;
                j = j + 1;
            } else {
                idpData.splice(j, 1);
            }
        }
    }

    /**
       Strips the supllied IdP list from the idpData
    */
    var stripHidden = function(hiddenList) {
    
        if (null == hiddenList || 0 == hiddenList.length) {
            return;
        }
        var i;
        var j;
        for (i = 0; i < hiddenList.length; i++) {
            for (j = 0; j < idpData.length; j++) {
                if (getEntityId(idpData[j]) == hiddenList[i]) {
                    idpData.splice(j, 1);
                    break;
                }
            }
        }
    }


    /**
     * Strip the "protocol://host" bit out of the URL and check the protocol
     * @param the URL to process
     * @return whether it starts with http: or https://
     */

    var validProtocol = function(s) {
        if (null === s) {
            return false;
        }
        var marker = "://";
        var protocolEnd = s.indexOf(marker);
        if (protocolEnd < 0) {
            return false;
        }
        s = s.substring(0, protocolEnd);
        if (s == "http" || s== "https") {
            return true;
        }
        return false;
    };

    /**
     * We need to cache bust on IE.  So how do we know?  Use a bigger hammer.
     */
    var isIE = function() {
        if (null == navigator) {
            return false;
        }
        var browserName = navigator.appName;
        if (null == browserName) {
            return false;
        }
        return (browserName == 'Microsoft Internet Explorer') ;
    } ;

    /**
     * Alternative to location.href=string
     *
     * Needed to cache bust Firefox
     */

    var dispatchTo = function(theParent, whereTo) {
        var aval = document.createElement('a');

        aval.href = whereTo;
        theParent.appendChild(aval);

        aval.click();
    }

    /**
       Loads the data used by the IdP selection UI.  Data is loaded 
       from a JSON document fetched from the given url.
      
       @param {Function} failureCallback A function called if the JSON
       document can not be loaded from the source.  This function will
       passed the {@link XMLHttpRequest} used to request the JSON data.
    */
    var load = function(dataSource){
        var xhr = null;

        try {
            xhr = new XMLHttpRequest();
        } catch (e) {}
        if (null == xhr) {
            //
            // EDS24. try to get 'Microsoft.XMLHTTP'
            //
            try {
                xhr = new ActiveXObject("Microsoft.XMLHTTP");
            } catch (e) {}
        }
        if (null == xhr) {
            //
            // EDS35. try to get 'Microsoft.XMLHTTP'
            //
            try {
                xhr = new  ActiveXObject('MSXML2.XMLHTTP.3.0');
            } catch (e) {}
        }
        if (null == xhr) {
            fatal(getLocalizedMessage('fatal.noXMLHttpRequest'));
            return false;
        }

        if (isIE()) {
            //
            // cache bust (for IE)
            //
            dataSource += '?random=' + (Math.random()*1000000);
        }

        //
        // Grab the data
        //
        xhr.open('GET', dataSource, false);
        if (typeof xhr.overrideMimeType == 'function') {
            xhr.overrideMimeType('application/json');
        }
        xhr.send(null);
        
        if(xhr.status == 200){
            //
            // 200 means we got it OK from as web source
            // if locally loading its 0.  Go figure
            //
            var jsonData = xhr.responseText;
            if(jsonData === null){
                fatal(getLocalizedMessage('fatal.noData'));
                return false;
            }

            //
            // Parse it
            //

            idpData = JSON.parse(jsonData);

        }else{
            fatal(getLocalizedMessage('fatal.loadFailed') + dataSource);
            return false;
        }
        return true;
    };

    /**
       Returns the idp object with the given name.

       @param (String) the name we are interested in
       @return (Object) the IdP we care about
    */

    var getIdPFor = function(idpName) {

        for (var i = 0; i < idpData.length; i++) {
            if (getEntityId(idpData[i]) == idpName) {
                return idpData[i];
            }
        }
        return null;
    };

    /**
       Returns a suitable image from the given IdP
       
       @param (Object) The IdP
       @return Object) a DOM object suitable for insertion
       
       TODO - rather more careful selection
    */

    var getImageForIdP = function(idp, useDefault) {

        var getBestFit = function(language) {
            //
            // See GetLocalizedEntry
            //
            var bestFit = null;
            var i;
            if (null == idp.Logos) {
                return null;
            }
            for (i in idp.Logos) {
                if (idp.Logos[i].lang == language &&
                    idp.Logos[i].width != null &&  
                    idp.Logos[i].width >= minWidth &&
                    idp.Logos[i].height != null && 
                    idp.Logos[i].height >= minHeight) {
                    if (bestFit === null) {
                        bestFit = idp.Logos[i];
                    } else {
                        me = Math.abs(bestRatio - Math.log(idp.Logos[i].width/idp.Logos[i].height));
                        him = Math.abs(bestRatio - Math.log(bestFit.width/bestFit.height));
                        if (him > me) {
                            bestFit = idp.Logos[i];
                        }
                    }
                }
            }
            return bestFit;
        } ;

        var bestFit = null;
        var img = document.createElement('img');
        setClass(img, 'IdPImg');

        bestFit = getBestFit(lang);
        if (null === bestFit && typeof majorLang != 'undefined') {
            bestFit = getBestFit(majorLang);
        }
        if (null === bestFit) {
            bestFit = getBestFit(null);
        }
        if (null === bestFit) {
            bestFit = getBestFit(defaultLang);
        }
               
        if (null === bestFit) {
            if (!useDefault) {
                return null;
            }
            img.src = defaultLogo;
            img.width = defaultLogoWidth;
            img.height = defaultLogoHeight;
            img.alt = getLocalizedMessage('defaultLogoAlt');
            return img;
        }

        img.src = bestFit.value;
        var altTxt = getLocalizedName(idp);
        if (altTxt.length > maxIdPCharsAltTxt) {
            altTxt = altTxt.substring(0, maxIdPCharsAltTxt) + '...';
        }
        img.alt = altTxt;

        var w = bestFit.width;
        var h = bestFit.height;
        if (w>maxWidth) {
            h = (maxWidth/w) * h;
            w = maxWidth;
        }
        if (h> maxHeight) {
            w = (maxHeight/h) * w;
            h = maxHeight;
        }
            
        img.setAttribute('width', w);
        img.setAttribute('height', h);
        return img;
    };

    // *************************************
    // Private functions
    //
    // GUI Manipulation
    //
    // *************************************
    
    /**
       Builds the IdP selection UI.

       Three divs. PreferredIdPTime, EntryTile and DropdownTile
       Optional div AutoDispatchPane
      
       @return {Element} IdP selector UI
    */
    var buildIdPSelector = function(){
        var containerDiv = buildDiv('IdPSelector');
        var preferredTileExists;
        preferredTileExists = buildPreferredIdPTile(containerDiv);
        buildIdPEntryTile(containerDiv, preferredTileExists);
        buildIdPDropDownListTile(containerDiv, preferredTileExists);
        if (null != autoFollowCookie) {
            buildAutoDispatchPane(containerDiv);
        }
        return containerDiv;
    };

    /**
      Builds a button for the provided IdP
        <div class="preferredIdPButton">
          <a href="XYX" onclick=setparm('ABCID')>
            <div class=
            <img src="https:\\xyc.gif"> <!-- optional -->
            XYX Text
          </a>
        </div>

      @param (Object) The IdP
      
      @return (Element) preselector for the IdP
    */

    var composePreferredIdPButton = function(idp, uniq, useDefault) {
        var div = buildDiv(undefined, 'PreferredIdPButton');
        var aval = document.createElement('a');
        var retString = returnIDParam + '=' + encodeURIComponent(getEntityId(idp));
        var retVal = returnString;
        var img = getImageForIdP(idp, useDefault);
        //
        // Compose up the URL
        //
        if (retVal.indexOf('?') == -1) {
            retString = '?' + retString;
        } else {
            retString = '&' + retString;
        }
        aval.href = retVal + retString;
        aval.onclick = function () {
            selectIdP(getEntityId(idp));
        };
        if (null != img) {
            var imgDiv=buildDiv(undefined, 'PreferredIdPImg');
            imgDiv.appendChild(img);
            aval.appendChild(imgDiv);
        }

        var nameDiv = buildDiv(undefined, 'TextDiv');
        var nameStr = getLocalizedName(idp);
        if (nameStr.length > maxIdPCharsButton) {
            nameStr = nameStr.substring(0, maxIdPCharsButton) + '...';
        }
        div.title = nameStr;
        nameDiv.appendChild(document.createTextNode(nameStr));
        aval.appendChild(nameDiv);

        div.appendChild(aval);
        return div;
    };

    /**
     * Builds and populated a text Div
     */
    var buildTextDiv = function(parent, textId)
    {
        var div  = buildDiv(undefined, 'TextDiv');
        var introTxt = document.createTextNode(getLocalizedMessage(textId)); 
        div.appendChild(introTxt);
        parent.appendChild(div);
    } ;

    var setSelector = function (selector, selected) {
        if (null === selected || 0 === selected.length || '-' == selected.value) {
            return;
        }
        var i = 0;
        while (i < selector.options.length) {
            if (selector.options[i].value == selected) {
                selector.options[i].selected = true;
                break;
            }
            i++;
        }
    }

    /**
       Builds the preferred IdP selection UI (top half of the UI w/ the
       IdP buttons)

       <div id=prefix+"PreferredIdPTile">
          <div> [see comprosePreferredIdPButton </div>
          [repeated]
       </div>
      
       @return {Element} preferred IdP selection UI
    */
    var buildPreferredIdPTile = function(parentDiv) {

        var preferredIdPs = getPreferredIdPs();
        if (0 === preferredIdPs.length) {
            return false;
        }

        var atLeastOneImg = doNotCollapse;
        for(var i = 0 ; i < maxPreferredIdPs && i < preferredIdPs.length; i++){
            if (preferredIdPs[i] && getImageForIdP(preferredIdPs[i], false)) {
                atLeastOneImg = true;
            }
        }
        
        var preferredIdPDIV;
        if (atLeastOneImg) {
            preferredIdPDIV = buildDiv('PreferredIdPTile');
        } else {
            preferredIdPDIV = buildDiv('PreferredIdPTileNoImg');
        }


        buildTextDiv(preferredIdPDIV, 'idpPreferred.label');


        for(var i = 0 ; i < maxPreferredIdPs && i < preferredIdPs.length; i++){
            if (preferredIdPs[i]) {
                var button = composePreferredIdPButton(preferredIdPs[i],i, atLeastOneImg);
                preferredIdPDIV.appendChild(button);
            }
        }

        parentDiv.appendChild(preferredIdPDIV);
        return true;
    };

    /**
     * Build the <form> from the return parameters
     */

    var buildSelectForm = function ()
    {
        var form = document.createElement('form');
        idpEntryDiv.appendChild(form);

        form.action = returnBase;
        form.method = 'GET';
        form.setAttribute('autocomplete', 'OFF');
        var i = 0;
        for (i = 0; i < returnParms.length; i++) {
            var hidden = document.createElement('input');
            hidden.setAttribute('type', 'hidden');
            hidden.name = returnParms[i][0];
            hidden.value= returnParms[i][1];
            form.appendChild(hidden);
        }

        return form;
    } ;


    /**
       Build the manual IdP Entry tile (bottom half of UI with
       search-as-you-type field).

       <div id = prefix+"IdPEntryTile">
         <form>
           <input type="text", id=prefix+"IdPSelectInput/> // select text box
           <input type="hidden" /> param to send
           <input type="submit" />
           
      
       @return {Element} IdP entry UI tile
    */
    var buildIdPEntryTile = function(parentDiv, preferredTile) {


        idpEntryDiv = buildDiv('IdPEntryTile');
        if (showListFirst) {
            idpEntryDiv.style.display = 'none';
        }
        
        var label = document.createElement('label');
        label.setAttribute('for', idPrefix + 'Input');

        if (preferredTile) {
            buildTextDiv(label, 'idpEntry.label');
        } else {
            buildTextDiv(label, 'idpEntry.NoPreferred.label');
        }

        var form = buildSelectForm();
        form.appendChild(label);
      
        var textInput = document.createElement('input');
        form.appendChild(textInput);

        textInput.type='text';
        setID(textInput, 'Input');

        var hidden = document.createElement('input');
        hidden.setAttribute('type', 'hidden');
        form.appendChild(hidden);

        hidden.name = returnIDParam;
        hidden.value='-';

        var button = buildContinueButton('Select');
        button.disabled = true;
        form.appendChild(button);
        
        form.onsubmit = function () {
            //
            // Make sure we cannot ask for garbage
            //
            if (null === hidden.value || 0 === hidden.value.length || '-' == hidden.value) {
                return false;
            }
            //
            // And always ask for the cookie to be updated before we continue
            //
            textInput.value = hidden.textValue;
            selectIdP(hidden.value);
            return true;
        };

        dropDownControl = new TypeAheadControl(idpData, textInput, hidden, button, maxIdPCharsDropDown, getLocalizedName, getEntityId, geticon, ie6Hack, alwaysShow, maxResults, getKeywords);

        var a = document.createElement('a');
        a.appendChild(document.createTextNode(getLocalizedMessage('idpList.showList')));
        a.href = '#';
        setClass(a, 'DropDownToggle');
        a.onclick = function() { 
            idpEntryDiv.style.display='none';
            setSelector(idpSelect, hidden.value);
            idpListDiv.style.display='';
            listButton.focus();
            return false;
        };
        idpEntryDiv.appendChild(a);
        buildHelpText(idpEntryDiv);
                                              
        parentDiv.appendChild(idpEntryDiv);
    };
    
    /**
       Builds the drop down list containing all the IdPs from which a
       user may choose.

       <div id=prefix+"IdPListTile">
          <label for="idplist">idpList.label</label>
          <form action="URL from IDP Data" method="GET">
          <select name="param from IdP data">
             <option value="EntityID">Localized Entity Name</option>
             [...]
          </select>
          <input type="submit"/>
       </div>
        
       @return {Element} IdP drop down selection UI tile
    */
    var buildIdPDropDownListTile = function(parentDiv, preferredTile) {
        idpListDiv = buildDiv('IdPListTile');
        if (!showListFirst) {
            idpListDiv.style.display = 'none';
        }

        var label = document.createElement('label');
        label.setAttribute('for', idPrefix + 'Selector');

        if (preferredTile) {
            buildTextDiv(label, 'idpList.label');
        } else {
            buildTextDiv(label, 'idpList.NoPreferred.label');
        }

        idpSelect = document.createElement('select');
        setID(idpSelect, 'Selector');
        idpSelect.name = returnIDParam;
        idpListDiv.appendChild(idpSelect);
        
        var idpOption = buildSelectOption('-', getLocalizedMessage('idpList.defaultOptionLabel'));
        idpOption.selected = true;

        idpSelect.appendChild(idpOption);
    
        var idp;
        for(var i=0; i<idpData.length; i++){
            idp = idpData[i];
            idpOption = buildSelectOption(getEntityId(idp), getLocalizedName(idp));
            idpSelect.appendChild(idpOption);
        }

        var form = buildSelectForm();
        form.appendChild(label);
        form.appendChild(idpSelect);

        form.onsubmit = function () {
            //
            // The first entery isn't selectable
            //
            if (idpSelect.selectedIndex < 1) {
                return false;
            }
            //
            // otherwise update the cookie
            //
            selectIdP(idpSelect.options[idpSelect.selectedIndex].value);
            return true;
        };

        var button = buildContinueButton('List');
        listButton = button;
        form.appendChild(button);

        idpListDiv.appendChild(form);

        //
        // The switcher
        //
        var a = document.createElement('a');
        a.appendChild(document.createTextNode(getLocalizedMessage('idpList.showSearch')));
        a.href = '#';
        setClass(a, 'DropDownToggle');
        a.onclick = function() { 
            idpEntryDiv.style.display='';
            idpListDiv.style.display='none';
            return false;
        };
        idpListDiv.appendChild(a);
        buildHelpText(idpListDiv);

        parentDiv.appendChild(idpListDiv);
    };

    var buildAutoDispatchPane = function(parent) {
        var inputName = 'IdPSelectAutoDisp'

        autoDispatchTile = buildDiv(undefined, 'autoDispatchArea');

        autoDispatchTile.appendChild(document.createTextNode(getLocalizedMessage('autoFollow.message')));
        //
        // The "clear" button
        //
        var but = document.createElement('input');
        but.setAttribute('type', 'radio');
        but.setAttribute('checked', 'checked');
        but.setAttribute('name', inputName);
        but.onclick = function () {
            setAutoDispatchCookie(0);
        }

        div = buildDiv(undefined, 'autoDispatchTile');
        div.appendChild(but);
        div.appendChild(document.createTextNode(getLocalizedMessage('autoFollow.never')));
        autoDispatchTile.appendChild(div);

        var i;
        for (i = 0; i < autoFollowCookieTTLs.length; i++) {
            //
            // The timed buttons
            //
            but = document.createElement('input');
            but.setAttribute('type', 'radio');
            but.setAttribute('name', inputName);

            but.life = autoFollowCookieTTLs[i];
            but.onclick = function () {
                var f = this.life;
                setAutoDispatchCookie(f);
            }

            div = buildDiv(undefined, 'autoDispatchTile');
            div.appendChild(but);
            div.appendChild(document.createTextNode(
                getLocalizedMessage('autoFollow.time'+i)));
            autoDispatchTile.appendChild(div);
        }

        parent.appendChild(autoDispatchTile);
    }

    /**
       Builds the 'continue' button used to submit the IdP selection.
      
       @return {Element} HTML button used to submit the IdP selection
    */
    var buildContinueButton = function(which) {
        var button  = document.createElement('input');
        button.setAttribute('type', 'submit');
        button.value = getLocalizedMessage('submitButton.label');
        setID(button, which + 'Button');

        return button;
    };

    /**
       Builds an aref to point to the helpURL
    */

    var buildHelpText = function(containerDiv) {
        var aval = document.createElement('a');
        aval.href = helpURL;
        aval.appendChild(document.createTextNode(getLocalizedMessage('helpText')));
        setClass(aval, 'HelpButton');
        containerDiv.appendChild(aval);
    } ;
    
    /**
       Creates a div element whose id attribute is set to the given ID.
      
       @param {String} id ID for the created div element
       @param {String} [class] class of the created div element
       @return {Element} DOM 'div' element with an 'id' attribute
    */
    var buildDiv = function(id, whichClass){
        var div = document.createElement('div');
        if (undefined !== id) {
            setID(div, id);
        }
        if(undefined !== whichClass) {

            setClass(div, whichClass);
        }
        return div;
    };
    
    /**
       Builds an HTML select option element
      
       @param {String} value value of the option when selected
       @param {String} label displayed label of the option
    */
    var buildSelectOption = function(value, text){
        var option = document.createElement('option');
        option.value = value;
        if (text.length > maxIdPCharsDropDown) {
            text = text.substring(0, maxIdPCharsDropDown);
        }
        option.appendChild(document.createTextNode(text));
        return option;
    };
    
    /**
       Sets the attribute 'id' on the provided object
       We do it through this function so we have a single
       point where we can prepend a value
       
       @param (Object) The [DOM] Object we want to set the attribute on
       @param (String) The Id we want to set
    */

    var setID = function(obj, name) {
        obj.id = idPrefix + name;
    };

    var setClass = function(obj, name) {
        obj.setAttribute('class', classPrefix + name);
    };

    /**
       Returns the DOM object with the specified id.  We abstract
       through a function to allow us to prepend to the name
       
       @param (String) the (unprepended) id we want
    */
    var locateElement = function(name) {
        return document.getElementById(idPrefix + name);
    };

    // *************************************
    // Private functions
    //
    // GUI actions.  Note that there is an element of closure going on
    // here since these names are invisible outside this module.
    // 
    //
    // *************************************

    /**
     * Base helper function for when an IdP is selected
     * @param (String) The UN-encoded entityID of the IdP
    */

    var selectIdP = function(idP) {
        updateSelectedIdPs(idP);
        saveUserSelectedIdPs(userSelectedIdPs);
    };

    // *************************************
    // Private functions
    //
    // Localization handling
    //
    // *************************************

    /**
       Gets a localized string from the given language pack.  This
       method uses the {@link langBundles} given during construction
       time.

       @param {String} messageId ID of the message to retrieve

       @return (String) the message
    */
    var getLocalizedMessage = function(messageId){

        var message = langBundle[messageId];
        if(!message){
            message = defaultLangBundle[messageId];
        }
        if(!message){
            message = 'Missing message for ' + messageId;
        }
        
        return message;
    };

    var getEntityId = function(idp) {
        return idp.entityID;
    };

    /**
       Returns the icon information for the provided idp

       @param (Object) an idp.  This should have an array 'names' with sub
        elements 'lang' and 'name'.

       @return (String) The localized name
    */
    var geticon = function(idp) {
        var i;

        if (null == idp.Logos) { 
            return null;
        }
        for (i =0; i < idp.Logos.length; i++) {
            var logo = idp.Logos[i];

            if (logo.height == "16" && logo.width == "16") {
                if (null == logo.lang ||
                    lang == logo.lang ||
                    (typeof majorLang != 'undefined' && majorLang == logo.lang) ||
                    defaultLang == logo.lang) {
                    return logo.value;
                }
            }
        }

        return null;
    } ;

    /**
       Returns the localized name information for the provided idp

       @param (Object) an idp.  This should have an array 'names' with sub
        elements 'lang' and 'name'.

       @return (String) The localized name
    */
    var getLocalizedName = function(idp) {
        var res = getLocalizedEntry(idp.DisplayNames);
        if (null !== res) {
            return res;
        }
        debug('No Name entry in any language for ' + getEntityId(idp));
        return getEntityId(idp);
    } ;

    var getKeywords = function(idp) {
        if (ignoreKeywords || null == idp.Keywords) {
            return null;
        }
        var s = getLocalizedEntry(idp.Keywords);

        return s;
    }
        
    var getLocalizedEntry = function(theArray){
        var i;

        //
        // try by full name
        //
        for (i in theArray) {
            if (theArray[i].lang == lang) {
                return theArray[i].value;
            }
        }
        //
        // then by major language
        //
        if (typeof majorLang != 'undefined') {
            for (i in theArray) {
                if (theArray[i].lang == majorLang) {
                    return theArray[i].value;
                }
            }
        }
        //
        // then by null language in metadata
        //
        for (i in theArray) {
            if (theArray[i].lang == null) {
                return theArray[i].value;
            }
        }
        
        //
        // then by default language
        //
        for (i in theArray) {
            if (theArray[i].lang == defaultLang) {
                return theArray[i].value;
            }
        }

        return null;
    };

    
    // *************************************
    // Private functions
    //
    // Cookie and preferred IdP Handling
    //
    // *************************************

    /**
       Gets the preferred IdPs.  The first elements in the array will
       be the preselected preferred IdPs.  The following elements will
       be those past IdPs selected by a user.  The size of the array
       will be no larger than the maximum number of preferred IdPs.
    */
    var getPreferredIdPs = function() {
        var idps = [];
        var offset = 0;
        var i;
        var j;

        //
        // populate start of array with preselected IdPs
        //
        if(null != preferredIdP){
            for(i=0; i < preferredIdP.length && i < maxPreferredIdPs; i++){
                idps[i] = getIdPFor(preferredIdP[i]);
                offset++;
            }
        }
        
        //
        // And then the cookie based ones
        //
        userSelectedIdPs = retrieveUserSelectedIdPs();
        for (i = offset, j=0; j < userSelectedIdPs.length && i < maxPreferredIdPs; j++){
            var cur_idp = getIdPFor(userSelectedIdPs[j]);
            if (typeof idps.indexOf === 'undefined') {
                idps.push(cur_idp);
                i++;
            }
            else if (idps.indexOf(cur_idp) === -1) {
                idps.push(cur_idp);
                i++;
            }
        }
        return idps;
    };

    /**
       Update the userSelectedIdPs list with the new value.

       @param (String) the newly selected IdP
    */
    var updateSelectedIdPs = function(newIdP) {

        //
        // We cannot use split since it does not appear to
        // work as per spec on ie8.
        //
        var newList = [];

        //
        // iterate through the list copying everything but the old
        // name
        //
        while (0 !== userSelectedIdPs.length) {
            var what = userSelectedIdPs.pop();
            if (what != newIdP) {
                newList.unshift(what);
            }
        }

        //
        // And shove it in at the top
        //
        newList.unshift(newIdP);
        userSelectedIdPs = newList;
        return;
    };

    /*
       Set the autoFollowCookie with a life of the specified number of days
       or clear it.

       @parm (integer) days  The cookie lifetime if >0.  If <=0 clear cookie

     */

    var setAutoDispatchCookie = function(days) {
        var expireDate;
        if(days > 0){
            var now = new Date();
            cookieTTL = days * 24 * 60 * 60 * 1000;
            expireDate = new Date(now.getTime() + cookieTTL);
        } else {
            expireDate = new Date(0);
        }
        document.cookie=autoFollowCookie + '=1;path=/;expires=' + expireDate.toUTCString();
    }

    /**
       Gets the value of the cookie with the provided name

       @param (string) name - the name to look for
       @return the value or null if no cookie of that name
    */

    var getCookieCalled = function (name) {

        var i, j;
        var cookies;

        cookies = document.cookie.split( ';' );
        for (i = 0; i < cookies.length; i++) {
            //
            // Do not use split('='), '=' is valid in Base64 encoding!
            //
            var cookie = cookies[i];
            var splitPoint = cookie.indexOf( '=' );
            var cookieName = cookie.substring(0, splitPoint);
                                
            if ( name ==  ( cookieName.replace(/^\s+|\s+$/g, ''))) {
                return cookie.substring(splitPoint+1);
            }
        }
        return null;
    }

    /**
       Gets the IdP previously selected by the user.

      @return {Array} user selected IdPs identified by their entity ID
    */
    var retrieveUserSelectedIdPs = function(){
        var userSelectedIdPs = [];
        var j;

        var cookieValues = getCookieCalled( '_saml_idp' );

        if ( cookieValues != null) {
            cookieValues = cookieValues.replace(/^\s+|\s+$/g, '');
            cookieValues = cookieValues.replace('+','%20');
            cookieValues = cookieValues.split('%20');
            for(j=cookieValues.length; j > 0; j--){
                if (0 === cookieValues[j-1].length) {
                    continue;
                }
                var dec = base64Decode(decodeURIComponent(cookieValues[j-1]));
                if (dec.length > 0) {
                    userSelectedIdPs.push(dec);
                }
            }
        }

        return userSelectedIdPs;
    };
    
    /**
       Saves the IdPs selected by the user.
      
       @param {Array} idps idps selected by the user
    */
    var saveUserSelectedIdPs = function(idps){
        var cookieData = [];
        var length = idps.length;

        if (noWriteCookie) {
            return;
        }

        if (length > 5) {
            length = 5;
        }
        for(var i=length; i > 0; i--){
            if (idps[i-1].length > 0) {
                cookieData.push(encodeURIComponent(base64Encode(idps[i-1])));
            }
        }
        
        var expireDate = null;
        if(samlIdPCookieTTL){
            var now = new Date();
            cookieTTL = samlIdPCookieTTL * 24 * 60 * 60 * 1000;
            expireDate = new Date(now.getTime() + cookieTTL);
        }
        
        document.cookie='_saml_idp' + '=' + cookieData.join('%20') + '; path = /' +
            ((expireDate===null) ? '' : '; expires=' + expireDate.toUTCString());
        
    };
    
    /**
       Base64 encodes the given string.
      
       @param {String} input string to be encoded
      
       @return {String} base64 encoded string
    */
    var base64Encode = function(input) {
        var output = '', c1, c2, c3, e1, e2, e3, e4;

        for ( var i = 0; i < input.length; ) {
            c1 = input.charCodeAt(i++);
            c2 = input.charCodeAt(i++);
            c3 = input.charCodeAt(i++);
            e1 = c1 >> 2;
            e2 = ((c1 & 3) << 4) + (c2 >> 4);
            e3 = ((c2 & 15) << 2) + (c3 >> 6);
            e4 = c3 & 63;
            if (isNaN(c2)){
                e3 = e4 = 64;
            } else if (isNaN(c3)){
                e4 = 64;
            }
            output += base64chars.charAt(e1) +
                base64chars.charAt(e2) +
                base64chars.charAt(e3) + 
                base64chars.charAt(e4);
        }

        return output;
    };
    
    /**
       Base64 decodes the given string.
      
       @param {String} input string to be decoded
      
       @return {String} base64 decoded string
    */
    var base64Decode = function(input) {
        var output = '', chr1, chr2, chr3, enc1, enc2, enc3, enc4;
        var i = 0;

        // Remove all characters that are not A-Z, a-z, 0-9, +, /, or =
        var base64test = /[^A-Za-z0-9\+\/\=]/g;
        input = input.replace(/[^A-Za-z0-9\+\/\=]/g, '');

        do {
            enc1 = base64chars.indexOf(input.charAt(i++));
            enc2 = base64chars.indexOf(input.charAt(i++));
            enc3 = base64chars.indexOf(input.charAt(i++));
            enc4 = base64chars.indexOf(input.charAt(i++));

            chr1 = (enc1 << 2) | (enc2 >> 4);
            chr2 = ((enc2 & 15) << 4) | (enc3 >> 2);
            chr3 = ((enc3 & 3) << 6) | enc4;

            output = output + String.fromCharCode(chr1);

            if (enc3 != 64) {
                output = output + String.fromCharCode(chr2);
            }
            if (enc4 != 64) {
                output = output + String.fromCharCode(chr3);
            }

            chr1 = chr2 = chr3 = '';
            enc1 = enc2 = enc3 = enc4 = '';

        } while (i < input.length);

        return output;
    };

    // *************************************
    // Private functions
    //
    // Error Handling.  we'll keep it separate with a view to eventual
    //                  exbedding into log4js
    //
    // *************************************
    /**
       
    */

    var fatal = function(message) {
        alert('FATAL - DISCO UI:' + message);
        var txt = document.createTextNode(message); 
        idpSelectDiv.appendChild(txt);
    };

    var debug = function() {
        //
        // Nothing
    };
}

// (new IdPSelectUI()).draw(new IdPSelectUIParms());
