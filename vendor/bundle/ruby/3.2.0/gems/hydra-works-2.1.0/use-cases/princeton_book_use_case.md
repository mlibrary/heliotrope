# Princeton Book Use Case

Sponsor: @jpstroop

```
Given a book with many pages, and many images of each page  
As a repository comprised of digitized books and manuscripts  
I want to maintain the relationships between images of a page and technical, 
    descriptive, and provenance metadata about each image
And I want to maintain sorting, label, and other metadata, as well as files
    that represent the whole object in one place
So that I can have multiple images of a page tied to one instance of a model 
    without relying on naming conventions (e.g. jp2_md5_checksum)  
```

Here are some example object we need to represent, and their characteristics, from least to most complex.

## A Photograph or Poster

Characteristics:

 * Descriptive MD
 * Rights MD (rights could theoretically apply at any level but that's not in my use case)
 * Provenance MD
 * A PDF
    * Technical metadata about the PDF
 * Has one or two images (of front and back):
    * A label for each surface
    * A sort integer for each surface
    * A TIFF of each surface
      * Technical MD about the TIFF
    * A JPEG2000 of each surface
      * Technical MD about the JP2
    * OCR of each page potentially in one or more flavors
      * Technical MD about the OCR

## A Book, Manuscript, or Ephemera

Characteristics:

 * Descriptive MD
 * Rights MD (rights could theoretically apply at any level but that's not in my use case)
 * Structural MD
 * Provenance MD
 * A PDF
    * Technical metadata about the PDF
 * Has many pages:
    * A label for each page
    * A sort integer for each page
    * A TIFF of each page 
      * Technical MD about the TIFF
    * A JPEG2000 of each page 
      * Technical MD about the JP2
    * OCR of each page potentially in one or more flavors
      * Technical MD about the OCR

## A Book Set or (or Multi-part Manuscripts)

Characteristics:

Can have one or more physical volumes; below assumes multi. 

 * Descriptive MD about the set
 * Rights MD about the set
 * For each member/volume:
   * Descriptive MD
   * Rights MD
   * Structural MD
   * Provenance MD
   * A PDF
      * Technical metadata about the PDF
   * Has many pages:
      * A label for each page
      * A sort integer for each page
      * A TIFF of each page 
        * Technical MD about the TIFF
      * A JPEG2000 of each page 
        * Technical MD about the JP2
      * OCR of each page potentially in one or more flavors
        * Technical MD about the OCR

## Photo Albums

Characteristics:

Can have one or more physical volumes. Below assumes this is the case.

 * Descriptive MD about the set
 * Rights MD about the set
 * For each member/volume:
   * Descriptive MD
   * Rights MD
   * Structural MD
   * Provenance MD
   * A PDF
      * Technical metadata about the PDF
   * Has many pages:
      * A label for each page
      * A sort integer for each page
      * A TIFF of each page 
        * Technical MD about the TIFF
      * A JPEG2000 of each page 
        * Technical MD about the JP2
      * OCR of each page potentially in one or more flavors
        * Technical MD about the OCR
      * Has many detail images representing individual photos mounted on the page:
        * A label for each page
        * A sort integer for each page
        * A TIFF of each page 
          * Technical MD about the TIFF
        * A JPEG2000 of each page 
          * Technical MD about the JP2


## Proposal

No doubt there are other ways, but I feel confident that [this approach](https://github.com/samvera/hydra-works/issues/9#issuecomment-58511913) would solve all of the above use cases. Validations included in subclasses of Hydra::Work would serve to constrain recursion.
