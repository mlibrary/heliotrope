# frozen_string_literal: true
def init
  super
  sections.last.place(:specs).before(:source)
end
