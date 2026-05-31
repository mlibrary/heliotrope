module Ldp::Uri
  extend Deprecation
  self.deprecation_horizon = 'ldp version 0.6'

  def uri str
    RDF::URI.new("http://www.w3.org/ns/ldp#") + str
  end
  deprecation_deprecate :uri

  def resource
    RDF::Vocab::LDP.Resource
  end
  deprecation_deprecate :resource

  def rdf_source
    RDF::Vocab::LDP.RDFSource
  end
  deprecation_deprecate :rdf_source

  def non_rdf_source
    RDF::Vocab::LDP.NonRDFSource
  end
  deprecation_deprecate :non_rdf_source

  def container
    RDF::Vocab::LDP.Container
  end
  deprecation_deprecate :container

  def basic_container
    RDF::Vocab::LDP.BasicContainer
  end
  deprecation_deprecate :basic_container

  def direct_container
    RDF::Vocab::LDP.DirectContainer
  end
  deprecation_deprecate :direct_container

  def indirect_container
    RDF::Vocab::LDP.IndirectContainer
  end
  deprecation_deprecate :indirect_container

  def contains
    RDF::Vocab::LDP.contains
  end
  deprecation_deprecate :contains

  def page
    RDF::Vocab::LDP.Page
  end
  deprecation_deprecate :page

  def page_of
    RDF::Vocab::LDP.pageOf
  end
  deprecation_deprecate :page_of

  def next_page
    RDF::Vocab::LDP.nextPage
  end
  deprecation_deprecate :next_page

  def membership_predicate
    RDF::Vocab::LDP.membershipPredicate
  end
  deprecation_deprecate :membership_predicate

  def prefer_empty_container
    RDF::Vocab::LDP.PreferEmptyContainer
  end

  def prefer_membership
    RDF::Vocab::LDP.PreferMembership
  end

  def prefer_containment
    RDF::Vocab::LDP.PreferContainment
  end

  def has_member_relation
    RDF::Vocab::LDP.hasMemberRelation
  end
  deprecation_deprecate :has_member_relation

  def member
    RDF::Vocab::LDP.member
  end
  deprecation_deprecate :member
end
