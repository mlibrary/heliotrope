$:.unshift(File.expand_path("../..", __FILE__))
require 'sparql/algebra'
require 'sxp'

module LD::Patch
  # Based on the SPARQL Algebra, operators for executing a patch
  #
  # @author [Gregg Kellogg](http://greggkellogg.net/)
  module Algebra
    autoload :Add,        'ld/patch/algebra/add'
    autoload :Bind,       'ld/patch/algebra/bind'
    autoload :Constraint, 'ld/patch/algebra/constraint'
    autoload :Cut,        'ld/patch/algebra/cut'
    autoload :Delete,     'ld/patch/algebra/delete'
    autoload :Index,      'ld/patch/algebra/index'
    autoload :Patch,      'ld/patch/algebra/patch'
    autoload :Path,       'ld/patch/algebra/path'
    autoload :Prefix,     'ld/patch/algebra/prefix'
    autoload :Reverse,    'ld/patch/algebra/reverse'
    autoload :UpdateList, 'ld/patch/algebra/update_list'
  end
end


