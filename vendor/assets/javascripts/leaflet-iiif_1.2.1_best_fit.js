/*
 * Leaflet-IIIF 1.2.1
 * IIIF Viewer for Leaflet
 * by Jack Reed, @mejackreed
 * respinos's best-fit with fractional zoom patch. Yay!
 * https://raw.githubusercontent.com/mlibrary/Leaflet-IIIF/6b33090c1b31e926a2cc555dbad2f5a935cfc2cc/leaflet-iiif.js
 */

L.TileLayer.Iiif = L.TileLayer.extend({
    options: {
        continuousWorld: true,
        tileSize: false,
        updateWhenIdle: true,
        tileFormat: 'jpg',
        fitBounds: true,
        setMaxBounds: false,
        bestFit: false,
        fractionalZoomPatch: true,
        marginTop: 0,
        marginRight: 0,
        marginBottom: 0,
        marginLeft: 0
    },

    initialize: function(url, options) {
        options = typeof options !== 'undefined' ? options : {};

        if (options.maxZoom) {
            this._customMaxZoom = true;
        }

        // Check for explicit tileSize set
        if (options.tileSize) {
            this._explicitTileSize = true;
        }

        // Check for an explicit quality
        if (options.quality) {
            this._explicitQuality = true;
        }

        if (options.bestFit) {
            options.setMaxBounds = true;
        }

        if ( location.hash.indexOf('debug') > -1 ) {
            options.bestFit = false;
        }

        options = L.setOptions(this, options);
        this._infoDeferred = new $.Deferred();
        this._infoUrl = url;
        this._baseUrl = this._templateUrl();
        this._getInfo();
    },
    getTileUrl: function(coords) {
        var _this = this,
            x = coords.x,
            y = (coords.y),
            zoom = _this._getZoomForUrl(),
            scale = Math.pow(2, _this.maxNativeZoom - zoom),
            tileBaseSize = _this.options.tileSize * scale,
            minx = (x * tileBaseSize),
            miny = (y * tileBaseSize),
            maxx = Math.min(minx + tileBaseSize, _this.x),
            maxy = Math.min(miny + tileBaseSize, _this.y);

        var xDiff = (maxx - minx);
        var yDiff = (maxy - miny);

        return L.Util.template(this._baseUrl, L.extend({
            format: _this.options.tileFormat,
            quality: _this.quality,
            region: [minx, miny, xDiff, yDiff].join(','),
            rotation: 0,
            size: _this._iiifSizeParam(Math.ceil(xDiff / scale), Math.ceil(yDiff / scale))
        }, this.options));
    },
    onAdd: function(map) {
        var _this = this;

        // Wait for deferred to complete
        $.when(_this._infoDeferred).done(function() {

            // Set maxZoom for map
            map._layersMaxZoom = _this.maxZoom;

            // Call add TileLayer
            L.TileLayer.prototype.onAdd.call(_this, map);

            if (_this.options.fitBounds) {
                _this._fitBounds();
            }

            if(_this.options.setMaxBounds) {
                _this._setMaxBounds();
            }

            // Reset tile sizes to prevent seams (https://github.com/Leaflet/Leaflet/issues/3575)
            _this.on('tileload', function(tile, url) {

                var height = tile.tile.naturalHeight,
                    width = tile.tile.naturalWidth;

                // in a departure from the commit referenced up top, we're adding a pixel to *all* tiles...
                // as scroll-wheel zoom manages to easily bring seams back otherwise
                tile.tile.style.width = (width + 1) + 'px';
                tile.tile.style.height = (height + 1) + 'px';

            });
        });
    },
    onRemove: function(map) {
        var _this = this;

        // Remove maxBounds set for this image
        if(_this.options.setMaxBounds) {
            map.setMaxBounds(null);
        }

        // Call remove TileLayer
        L.TileLayer.prototype.onRemove.call(_this, map);

    },
    _fitBounds: function() {
        var _this = this;

        if ( _this.options.bestFit && ( _this.x < _this._map.x ) && ( _this.y < _this._map.y ) ) {
            // disable bestFit
            _this.options.bestFit = false;
        }

        // Find best zoom level and center map
        var initialZoom = _this._getInitialZoom(_this._map.getSize());
        var imageSize = _this._getImageSize(initialZoom);

        var margins = this._calculateMargins(imageSize);

        var sw = _this._map.options.crs.pointToLatLng(L.point(0, imageSize.y + margins.bottom), initialZoom);
        var ne = _this._map.options.crs.pointToLatLng(L.point(imageSize.x + margins.left, 0), initialZoom);
        var bounds = L.latLngBounds(sw, ne);

        var boundsOptions = {
            paddingTopLeft: [ margins.left, margins.top ],
            paddingBottomRight: [ margins.right, margins.bottom ]
        };

        if ( this.options.bestFit ) {
            this._map.options.zoomSnap = 0.0;
            this._map.options.zoomDelta = 0.5;
            this._map.options.minZoom = initialZoom;
            boundsOptions.maxZoom = _this.maxNativeZoom;
        }

        _this._map.fitBounds(bounds, boundsOptions);
    },
    _setMaxBounds: function() {
        var _this = this;

        // Find best zoom level, center map, and constrain viewer
        var initialZoom = _this._getInitialZoom(_this._map.getSize());
        var imageSize = _this._getImageSize(initialZoom);
        var sw = _this._map.options.crs.pointToLatLng(L.point(0, imageSize.y), initialZoom);
        var ne = _this._map.options.crs.pointToLatLng(L.point(imageSize.x, 0), initialZoom);
        var bounds = L.latLngBounds(sw, ne);

        _this._map.setMaxBounds(bounds, true);
    },
    _getInfo: function() {
        var _this = this;

        // Look for a way to do this without jQuery
        $.getJSON(_this._infoUrl)
            .done(function(data) {
                _this.y = data.height;
                _this.x = data.width;
                _this._id = data['@id'];
                _this._baseUrl = _this._templateUrl();

                var tierSizes = [],
                    imageSizes = [],
                    scale,
                    width_,
                    height_,
                    tilesX_,
                    tilesY_;

                // Set quality based off of IIIF version
                if (data.profile instanceof Array) {
                    _this.profile = data.profile[0];
                }else {
                    _this.profile = data.profile;
                }

                _this._setQuality();

                // Unless an explicit tileSize is set, use a preferred tileSize
                if (!_this._explicitTileSize) {
                    // Set the default first
                    _this.options.tileSize = 256;
                    if (data.tiles) {
                        // Image API 2.0 Case
                        _this.options.tileSize = data.tiles[0].width;
                    } else if (data.tile_width){
                        // Image API 1.1 Case
                        _this.options.tileSize = data.tile_width;
                    }
                }

                function ceilLog2(x) {
                    return Math.ceil(Math.log(x) / Math.LN2);
                };

                // Calculates maximum native zoom for the layer
                _this.maxNativeZoom = Math.max(ceilLog2(_this.x / _this.options.tileSize),
                    ceilLog2(_this.y / _this.options.tileSize));

                // Enable zooming further than native if maxZoom option supplied
                if (_this._customMaxZoom && _this.options.maxZoom > _this.maxNativeZoom) {
                    _this.maxZoom = _this.options.maxZoom;
                }
                else {
                    _this.maxZoom = _this.maxNativeZoom;
                }

                for (var i = 0; i <= _this.maxZoom; i++) {
                    scale = Math.pow(2, _this.maxNativeZoom - i);
                    width_ = Math.ceil(_this.x / scale);
                    height_ = Math.ceil(_this.y / scale);
                    tilesX_ = Math.ceil(width_ / _this.options.tileSize);
                    tilesY_ = Math.ceil(height_ / _this.options.tileSize);
                    tierSizes.push([tilesX_, tilesY_]);
                    imageSizes.push(L.point(width_,height_));
                }

                _this._tierSizes = tierSizes;
                _this._imageSizes = imageSizes;

                // Resolved Deferred to initiate tilelayer load
                _this._infoDeferred.resolve();
            });
    },

    _setQuality: function() {
        var _this = this;
        var profileToCheck = _this.profile;

        if (_this._explicitQuality) {
            return;
        }

        // If profile is an object
        if (typeof(profileToCheck) === 'object') {
            profileToCheck = profileToCheck['@id'];
        }

        // Set the quality based on the IIIF compliance level
        switch (true) {
            case /^http:\/\/library.stanford.edu\/iiif\/image-api\/1.1\/compliance.html.*$/.test(profileToCheck):
                _this.options.quality = 'native';
                break;
            // Assume later profiles and set to default
            default:
                _this.options.quality = 'default';
                break;
        }
    },

    _infoToBaseUrl: function() {
        return this._id ? (this._id + '/') : this._infoUrl.replace('info.json', '');
    },
    _templateUrl: function() {
        return this._infoToBaseUrl() + '{region}/{size}/{rotation}/{quality}.{format}';
    },
    _isValidTile: function(coords) {
        var _this = this,
            zoom = _this._getZoomForUrl(),
            sizes = _this._tierSizes[zoom],
            x = coords.x,
            y = (coords.y);

        if (!sizes) return false;
        if (x < 0 || sizes[0] <= x || y < 0 || sizes[1] <= y) {
            return false;
        }else {
            return true;
        }
    },
    _iiifSizeParam: function(x, y) {
        if ( x && x > this.options.tileSize ) { x = this.options.tileSize; }
        if ( y && y > this.options.tileSize ) { y = this.options.tileSize; }
        if (x >= y) {
            return x + ',';
        } else {
            return ',' + y;
        }
    },
    _calculateMargins: function(imageSize) {
        var margins = { top: 0, right: 0, bottom: 0, left: 0};
        if ( this.options.marginBottom ) {
            margins.bottom = imageSize.y * this.options.marginBottom;
        }
        if ( this.options.marginLeft ) {
            margins.left = imageSize.x * this.options.marginLeft;
        }
        return margins;
    },
    _getImageSize: function(initialZoom) {
        var _this = this;
        var imageSize = _this._imageSizes[initialZoom];
        if ( imageSize === undefined ) {
            imageSize = {};
            var scale = Math.pow(2, _this.maxNativeZoom - initialZoom);
            imageSize.y = _this.y / scale;
            imageSize.x = _this.x / scale;
        }
        return imageSize;
    },
    _getInitialBestFitZoom: function(mapSize) {
        var _this = this,
            imageSize,
            key;

        imageSize = this._imageSizes[this.maxNativeZoom];
        key = imageSize.x > imageSize.y ? 'x' : 'y';

        var fraction = imageSize[key] / mapSize[key];
        var exp = Math.log2(fraction);
        if ( exp >= 0 ) {
            var zoom = this.maxNativeZoom - exp,
                original_zoom = zoom;

            // round the zoom for simpler processing
            zoom = Math.round(zoom * 100) / 100;
            return zoom;
        }
        return this.maxNativeZoom;
    },
    _getInitialZoom: function (mapSize) {
        var _this = this,
            tolerance = 0.8,
            imageSize;

        if ( this.options.bestFit ) { return this._getInitialBestFitZoom(mapSize); }

        for (var i = _this.maxNativeZoom; i >= 0; i--) {
            imageSize = this._imageSizes[i];
            if (imageSize.x * tolerance < mapSize.x && imageSize.y * tolerance < mapSize.y) {
                return i;
            }
        }
        // return a default zoom
        return 2;
    }
});

L.tileLayer.iiif = function(url, options) {
    return new L.TileLayer.Iiif(url, options);
};
