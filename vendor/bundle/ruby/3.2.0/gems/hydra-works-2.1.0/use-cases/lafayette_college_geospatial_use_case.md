# Lafayette College Libraries Geospatial Data Set Use Case

Sponsor: @jrgriffiniii

```
Given an Esri Shapefile containing many Features
As a user
I want to view all point Features in the Shapefile on a raster base layer
And I want to view all polygon Features in the Shapefile on a raster base layer
And I want to discover all Features for the related Shapefile
And I want to discover all Features using a box bounded by geospatial coordinates
And I want to discover the Shapefile using MODS element values
And I want to discover the Shapefile using a box bounded by geospatial coordinates
```

```
Given an Esri Shapefile containing many Features
As a curator
Or as an archivist
I want to create MODS element values for Esri Shapefiles
And I want to edit MODS element values for Esri Shapefiles
And I want to delete MODS element values for Esri Shapefiles
```

```
Given an Esri Shapefile containing many Features
And given a TIFF image
As a curator
Or as an archivist
I want to reference a TIFF image from a Feature
And I want to view a thumbnail for the referenced TIFF image when I click on the Feature
```

```
Given a GeoTIFF referencing many geospatial coordinates
As a user
I want to view the GeoTIFF image on a raster base layer
And I want to discover the GeoTIFF using a box bounded by geospatial coordinates
And I want to discover the GeoTIFF using MODS element values
```

```
Given a GeoTIFF referencing many geospatial coordinates
As a curator
Or as an archivist
I want to create MODS element values for Esri Shapefiles
And I want to edit MODS element values for Esri Shapefiles
And I want to delete MODS element values for Esri Shapefiles
```

```
Given an Esri Shapefile containing many Features
As a user
I want to view all point Features in the Shapefile and the GeoTIFF image on a raster base layer
And I want to view all polygon Features in the Shapefile and the GeoTIFF image on a raster base layer
```

## Esri Shapefile

Characteristics:

 * Descriptive MD
    * We've been working with the MODS
 * Rights MD
 * Geospatial MD
   * Ideally, this should be managed within either FGDC XML Documents or in compliance with ISO 19139
 * Keyhole Markup Language (KML) Document
 * GeoJSON Objects
   * Preferably, these would be deprecated in favor of [TopoJSON Objects](https://github.com/mbostock/topojson/wiki)

## GeoTIFF Image

Characteristics:

 * Descriptive MD
   * We've been working with the MODS
 * Rights MD
 * Technical MD
   * Structured using a METS-PREMIS profile and extracted using the FITS
   * Perhaps gdalinfo could also be integrated for additional metadata?
