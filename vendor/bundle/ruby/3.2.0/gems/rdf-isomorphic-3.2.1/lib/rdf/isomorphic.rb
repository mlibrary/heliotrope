require 'digest/sha1'
require 'rdf'
require 'rdf/ntriples'


module RDF
  ##
  # Isomorphism for rdf.rb Enumerables
  #
  # RDF::Isomorphic provides the functions isomorphic_with and bijection_to for RDF::Enumerable.
  #
  # @see https://ruby-rdf.github.io/rdf/
  # @see https://www.hpl.hp.com/techreports/2001/HPL-2001-293.pdf
  module Isomorphic
    autoload :VERSION,        'rdf/isomorphic/version'

    # Returns `true` if this RDF::Enumerable is isomorphic with another.
    #
    # @param canonicalize [Boolean] (false)
    #   If `true`, RDF::Literals will be canonicalized while producing a bijection.  This results in broader matches for isomorphism in the case of equivalent literals with different representations.
    # @param opts [Hash<Symbol => Any>] other options ignored
    # @param other [RDF::Enumerable]
    # @return [Boolean]
    # @example
    #     repository_a.isomorphic_with repository_b #=> true
    def isomorphic_with?(other, canonicalize: false, **opts)
      !(bijection_to(other, canonicalize: false, **opts).nil?)
    end

    alias_method :isomorphic?, :isomorphic_with?


    # Returns a hash of RDF:Nodes: RDF::Nodes representing an isomorphic
    # bijection of this RDF::Enumerable's to another RDF::Enumerable's blank
    # nodes, or nil if a bijection cannot be found.
    #
    # Takes a canonicalize: true argument.  If true, RDF::Literals will be
    # canonicalized while producing a bijection.  This results in broader
    # matches for isomorphism in the case of equivalent literals with different
    # representations.
    #
    # @example
    #     repository_a.bijection_to repository_b
    # @param other [RDF::Enumerable]
    # @param canonicalize [Boolean] (false)
    #   If true, RDF::Literals will be canonicalized while producing a bijection.  This results in broader matches for isomorphism in the case of equivalent literals with different representations.
    # @param opts [Hash<Symbol => Any>] other options ignored
    # @return [Hash, nil]
    def bijection_to(other, canonicalize: false, **opts)

      grounded_stmts_match = (count == other.count)

      grounded_stmts_match &&= each_statement.all? do | stmt |
        stmt.node? || other.has_statement?(stmt)
      end

      if grounded_stmts_match
        # blank_stmts and other_blank_stmts are just a performance
        # consideration--we could just as well pass in self and other.  But we
        # will be iterating over this list quite a bit during the algorithm, so
        # we break it down to the parts we're interested in.
        blank_stmts = find_all { |statement| statement.node? }
        other_blank_stmts = other.find_all { |statement| statement.node? }

        nodes = RDF::Isomorphic.blank_nodes_in(blank_stmts)
        other_nodes = RDF::Isomorphic.blank_nodes_in(other_blank_stmts)
        build_bijection_to blank_stmts, nodes, other_blank_stmts, other_nodes,
          these_grounded_hashes: {},
          other_grounded_hashes: {},
          canonicalize: false
      else
        nil
      end

    end

    private

    # The main recursive bijection algorithm.
    #
    # This algorithm is very similar to the one explained by Jeremy Carroll in
    # https://www.hpl.hp.com/techreports/2001/HPL-2001-293.pdf. Page 12 has the
    # relevant pseudocode.
    #
    # Many more comments are in the method itself.
    #
    # @param [RDF::Enumerable]  anon_stmts
    # @param [Array]            nodes
    # @param [RDF::Enumerable]  other_anon_stmts
    # @param [Array]            other_nodes
    # @param [Hash]             these_grounded_hashes
    # @param [Hash]             other_grounded_hashes
    # @param canonicalize [Boolean] (false)
    #   If true, RDF::Literals will be canonicalized while producing a bijection.  This results in broader matches for isomorphism in the case of equivalent literals with different representations.
    # @return [nil,Hash]
    # @private
    def build_bijection_to(anon_stmts, nodes, other_anon_stmts, other_nodes,
                           these_grounded_hashes: {},
                           other_grounded_hashes: {},
                           canonicalize: false)

      # Create a hash signature of every node, based on the signature of
      # statements it exists in.  
      # We also save hashes of nodes that cannot be reliably known; we will use
      # that information to eliminate possible recursion combinations.
      # 
      # Any mappings given in the method parameters are considered grounded.
      these_hashes, these_ungrounded_hashes = RDF::Isomorphic.hash_nodes(anon_stmts, nodes, these_grounded_hashes, canonicalize: canonicalize)
      other_hashes, other_ungrounded_hashes = RDF::Isomorphic.hash_nodes(other_anon_stmts, other_nodes, other_grounded_hashes, canonicalize: canonicalize)

      # Grounded hashes are built at the same rate between the two graphs (if
      # they are isomorphic).  If there exists a grounded node in one that is
      # not in the other, we can just return.  Ungrounded nodes might still
      # conflict, so we don't check them.  This is a little bit messy in the
      # middle of the method, and probably slows down isomorphic checks,  but
      # prevents almost-isomorphic cases from getting nutty.
      return nil if these_hashes.values.any? { |hash| !(other_hashes.values.member?(hash)) }
      return nil if other_hashes.values.any? { |hash| !(these_hashes.values.member?(hash)) }

      # Using the created hashes, map nodes to other_nodes
      # Ungrounded hashes will also be equal, but we keep the distinction
      # around for when we recurse later (we only recurse on ungrounded nodes)
      bijection = {}
      nodes.each do | node |
        other_node, _ = other_ungrounded_hashes.find do | other_node, other_hash |
          # we need to use eql?, as coincedentally-named bnode identifiers are == in rdf.rb
          these_ungrounded_hashes[node].eql? other_hash
        end
        next unless other_node
        bijection[node] = other_node

        # Deletion is required to keep counts even; two nodes with identical
        # signatures can biject to each other at random.
        other_ungrounded_hashes.delete other_node
      end

      # bijection is now a mapping of nodes to other_nodes.  If all are
      # accounted for on both sides, we have a bijection.
      #
      # If not, we will speculatively mark pairs with matching ungrounded
      # hashes as bijected and recurse.
      unless (bijection.keys.sort == nodes.sort) && (bijection.values.sort == other_nodes.sort)
        bijection = nil
        nodes.any? do | node |

          # We don't replace grounded nodes' hashes
          next if these_hashes.member? node
          other_nodes.any? do | other_node |

            # We don't replace grounded other_nodes' hashes
            next if other_hashes.member? other_node

            # The ungrounded signature must match for this to potentially work
            next unless these_ungrounded_hashes[node] == other_ungrounded_hashes[other_node]

            hash = Digest::SHA1.hexdigest(node.to_s)
            bijection = build_bijection_to(anon_stmts, nodes,
                         other_anon_stmts, other_nodes,
                         these_grounded_hashes: these_hashes.merge( node => hash),
                         other_grounded_hashes: other_hashes.merge(other_node => hash),
                         canonicalize: canonicalize)
          end
          bijection
        end
      end

      bijection
    end

    # Blank nodes appearing in given list of statements
    # @private
    # @param [Array<RDF::Statement>] blank_stmt_list
    # @return [Array<RDF::Node>]
    def self.blank_nodes_in(blank_stmt_list)
      blank_stmt_list.map {|statement | statement.terms.select(&:node?)}.flatten.uniq
    end

    # Given a set of statements, create a mapping of node => SHA1 for a given
    # set of blank nodes.  grounded_hashes is a mapping of node => SHA1 pairs
    # that we will take as a given, and use those to make more specific
    # signatures of other nodes.  
    #
    # Returns a tuple of hashes:  one of grounded hashes, and one of all
    # hashes.  grounded hashes are based on non-blank nodes and grounded blank
    # nodes, and can be used to determine if a node's signature matches
    # another.
    #
    # @param [Array] statements 
    # @param [Array] nodes
    # @param [Hash] grounded_hashes
    # @private
    # @return [Hash, Hash]
    def self.hash_nodes(statements, nodes, grounded_hashes, canonicalize: false)
      hashes = grounded_hashes.dup
      ungrounded_hashes = {}
      hash_needed = true

      # We may have to go over the list multiple times.  If a node is marked as
      # grounded, other nodes can then use it to decide their own state of
      # grounded.
      while hash_needed
        starting_grounded_nodes = hashes.size
        nodes.each do | node |
          unless hashes.member? node
            grounded, hash = node_hash_for(node, statements, hashes, canonicalize: canonicalize)
            if grounded
              hashes[node] = hash
            end
            ungrounded_hashes[node] = hash
          end
        end
        # after going over the list, any nodes with a unique hash can be marked
        # as grounded, even if we have not tied them back to a root yet.
        uniques = {}
        ungrounded_hashes.each do |node, hash|
          uniques[hash] = uniques.has_key?(hash) ? false : node
        end
        uniques.each do |hash, node|
          hashes[node] = hash if node
        end
        hash_needed = starting_grounded_nodes != hashes.size
      end
      [hashes,ungrounded_hashes]
    end

    # Generate a hash for a node based on the signature of the statements it
    # appears in.  Signatures consist of grounded elements in statements
    # associated with a node, that is, anything but an ungrounded anonymous
    # node.  Creating the hash is simply hashing a sorted list of each
    # statement's signature, which is itself a concatenation of the string form
    # of all grounded elements.
    #
    # Nodes other than the given node are considered grounded if they are a
    # member in the given hash.
    #
    # Returns a tuple consisting of grounded being true or false and the String
    # for the hash
    # @private
    # @param [RDF::Node] node
    # @param [Array<RDF::Statement>] statements
    # @param [Hash] hashes
    # @param [Boolean] canonicalize
    # @return [Boolean, String]
    def self.node_hash_for(node, statements, hashes, canonicalize:)
      statement_signatures = []
      grounded = true
      statements.each do | statement |
        if statement.terms.include?(node)
          statement_signatures << hash_string_for(statement, hashes, node, canonicalize: canonicalize)
          statement.terms.each do | resource |
            grounded = false unless grounded?(resource, hashes) || resource == node
          end
        end
      end
      # Note that we sort the signatures--without a canonical ordering, 
      # we might get different hashes for equivalent nodes.
      [grounded,Digest::SHA1.hexdigest(statement_signatures.sort.to_s)]
    end

    # Provide a string signature for the given statement, collecting
    # string signatures for grounded node elements.
    # return [String]
    # @private
    def self.hash_string_for(statement, hashes, node, canonicalize:)
      statement.terms.map {|r| string_for_node(r, hashes, node, canonicalize: canonicalize)}.join("")
    end

    # Returns true if a given node is grounded
    # A node is groundd if it is not a blank node or it is included
    # in the given mapping of grounded nodes.
    # @return [Boolean]
    # @private
    def self.grounded?(node, hashes)
      (!(node.node?)) || (hashes.member? node)
    end

    # Provides a string for the given node for use in a string signature
    # Non-anonymous nodes will return their string form.  Grounded anonymous
    # nodes will return their hashed form.
    # @return [String]
    # @private
    def self.string_for_node(node, hashes,target, canonicalize:)
      case
        when node.nil?
          ""
        when node == target
          "itself"
        when node.node? && hashes.member?(node)
          hashes[node]
        when node.node?
          "a blank node"
        # RDF.rb auto-boxing magic makes some literals the same when they
        # should not be; the ntriples serializer will take care of us
        when node.literal?
          node.class.name + RDF::NTriples.serialize(canonicalize ? node.canonicalize : node)
        else
          node.to_s
      end
    end
  end


  # Extend RDF::Enumerables with these functions.
  module Enumerable
    include RDF::Isomorphic
  end
  class Enumerable::Enumerator
    include RDF::Isomorphic
  end
end

