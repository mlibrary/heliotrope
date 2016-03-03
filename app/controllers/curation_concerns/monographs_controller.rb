# Generated via
#  `rails generate curation_concerns:work Monograph`

class CurationConcerns::MonographsController < ApplicationController
  include CurationConcerns::CurationConcernController
  set_curation_concern_type Monograph
end
