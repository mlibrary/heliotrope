# OpenSeadragon [![Gem Version](https://badge.fury.io/rb/openseadragon.png)](http://badge.fury.io/rb/openseadragon)

OpenSeadragon is a javascript library for displaying tiling images. This gem packages those assets and some Rails helpers for using them.

http://openseadragon.github.io/

## Installation

Add the gem to your Gemfile:

```ruby
gem 'openseadragon'
```

Run bundle install: 

```
$ bundle install
```

And run the openseadragon-rails install generator:

```
$ bundle exec rails g openseadragon:install
```

The generator will install the Rails helpers and openseadragon assets.

## Usage

This gem provides two helpers, `#picture_tag` and `#openseadragon_picture_tag`.


### picture_tag

The `#picture_tag` helper creates [HTML5 <picture> tags](http://www.w3.org/TR/html-picture-element/).

In the simple case, a view like:

```ruby
picture_tag 'page1.jpg', 'page2.jpg', 'page3.jpg'
```

Creates the HTML like:

```html
<picture>
  <source src="page1.jpg" />
  <source src="page2.jpg" />
  <source src="page3.jpg" />
</picture>
```

You can control the attributes on `<picture>` and `<source>` elements:

```ruby
picture_tag ['page1.jpg' => { id: 'first-picture'}], 'page2.jpg', 'page3.jpg', { class: "picture-image" }, { id: 'my-picture'}
```

```html
<picture id="my-picture">
  <source class="picture-image" id="first-picture" src="page1.jpg">
  <source class="picture-image" src="page2.jpg">
  <source class="picture-image" src="page3.jpg">
</picture>
```

### openseadragon_picture_tag

If you have an OpenSeaDragon tilesource, you can use this helper to construct a HTML5 `<picture>` that will render as an OpenSeaDragon tile viewer.

```ruby
openseadragon_picture_tag 'page1.jpg'
```

```html
<picture data-openseadragon="true">
  <source media="openseadragon" src="page1.jpg" />
</picture>
```

This gem includes some javascript that translates that markup to the OSD viewer.

As with `#picture_tag`, you can provide additional options.

```ruby
openseadragon_picture_tag 'page1.jpg', 'path/to/info.json', ['some-custom-tilesource' => { Image: {  xmlns: "...", Url: '...', Format: 'jpg', Overlap: 2}}], { class: 'osd-image'}, { data: { openseadragon: { preserveViewport: true, visibilityRatio: 1}}}
```

```html
<picture data-openseadragon="{&quot;preserveViewport&quot;:true,&quot;visibilityRatio&quot;:1}">
    <source class="osd-image" media="openseadragon" src="page1.jpg" />
    <source class="osd-image" media="openseadragon" src="path/to/info.json" />
    <source class="osd-image" data-openseadragon="{&quot;Image&quot;:{&quot;xmlns&quot;:&quot;...&quot;,&quot;Url&quot;:&quot;...&quot;,&quot;Format&quot;:&quot;jpg&quot;,&quot;Overlap&quot;:2}}" media="openseadragon" src="some-custom-tilesource" />
</picture>
```

The `src` attribute (or the JSON-encoded options given in the `data-openseadragon`) are translated  into an OpenSeaDragon `tilesource` configuration.
