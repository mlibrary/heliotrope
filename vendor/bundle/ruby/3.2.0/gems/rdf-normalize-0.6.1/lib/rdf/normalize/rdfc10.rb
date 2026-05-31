require 'rdf/nquads'
begin
  require 'json'
rescue LoadError
  # Used for debug output
end

module RDF::Normalize
  class RDFC10 < Base
    include RDF::Enumerable
    include RDF::Util::Logger

    ##
    # Create an enumerable with grounded nodes
    #
    # @param [RDF::Enumerable] enumerable
    # @option options [Integer] :max_calls (40)
    #   Maximum number of calls allowed for recursive blank node labeling,
    #   as a multiple of the total number of blank nodes in the dataset.
    # @return [RDF::Enumerable]
    # raise [RuntimeError] if the maximum number of levels of recursion is exceeded.
    def initialize(enumerable, **options)
      @dataset, @options = enumerable, options
    end

    # Yields each normalized statement
    def each(&block)
      ns = NormalizationState.new(**@options)
      log_debug("ca:")
      log_debug("  log point", "Entering the canonicalization function (4.5.3).")
      log_depth(depth: 2) {normalize_statements(ns, &block)}
    end

    # Returns a map from input blank node identifiers to canonical blank node identifiers.
    #
    # @return [Hash{String => String}]
    def to_hash
      ns = NormalizationState.new(**@options)
      log_debug("ca:")
      log_debug("  log point", "Entering the canonicalization function (4.5.3).")
      log_depth(depth: 2) {normalize_statements(ns)}
      ns.canonical_issuer.to_hash
    end

    #
    protected
    def normalize_statements(ns, &block)
      # Step 2: Map BNodes to the statements they are used by
      dataset.each_statement do |statement|
        statement.to_quad.compact.select(&:node?).each do |node|
          ns.add_statement(node, statement)
        end
      end
      log_debug("ca.2:")
      log_debug("  log point", "Extract quads for each bnode (4.5.3 (2)).")
      log_debug("  Bnode to quads:")
      if logger && logger.level == 0
        ns.bnode_to_statements.each do |bn, statements|
          log_debug("    #{bn.id}:")
          statements.each do |s|
            log_debug {"      - #{s.to_nquads.strip}"}
          end
        end
      end

      ns.hash_to_bnodes = {}

      # Step 3: Calculate hashes for first degree nodes
      log_debug("ca.3:")
      log_debug("  log point", "Calculated first degree hashes (4.5.3 (3)).")
      log_debug("  with:")
      ns.bnode_to_statements.each_key do |node|
        log_debug("    - identifier") {node.id}
        log_debug("      h1dq:")
        hash = log_depth(depth: 8) {ns.hash_first_degree_quads(node)}
        ns.add_bnode_hash(node, hash)
      end

      # Step 4: Create canonical replacements for hashes mapping to a single node
      log_debug("ca.4:")
      log_debug("  log point", "Create canonical replacements for hashes mapping to a single node (4.5.3 (4)).")
      log_debug("  with:") unless ns.hash_to_bnodes.empty?
      ns.hash_to_bnodes.keys.sort.each do |hash|
        identifier_list = ns.hash_to_bnodes[hash]
        next if identifier_list.length > 1
        node = identifier_list.first
        id = ns.canonical_issuer.issue_identifier(node)
        log_debug("    - identifier") {node.id}
        log_debug("      hash", hash)
        log_debug("      canonical label", id)
        ns.hash_to_bnodes.delete(hash)
      end

      # Step 5: Iterate over hashs having more than one node
      log_debug("ca.5:") unless ns.hash_to_bnodes.empty?
      log_debug("  log point", "Calculate hashes for identifiers with shared hashes (4.5.3 (5)).")
      log_debug("  with:") unless ns.hash_to_bnodes.empty?

      # Initialize the number of calls allowed to hash_n_degree_quads
      # as a multiple of the total number of blank nodes in the dataset.
      ns.max_calls = ns.bnode_to_statements.keys.length * @options.fetch(:max_calls, 40)

      ns.hash_to_bnodes.keys.sort.each do |hash|
        identifier_list = ns.hash_to_bnodes[hash]

        log_debug("    - hash", hash) 
        log_debug("      identifier list") {identifier_list.map(&:id).to_json(indent: ' ')}
        hash_path_list = []

        # Create a hash_path_list for all bnodes using a temporary identifier used to create canonical replacements
        log_debug("      ca.5.2:")
        log_debug("        log point", "Calculate hashes for identifiers with shared hashes (4.5.3 (5.2)).")
        log_debug("        with:") unless identifier_list.empty?
        identifier_list.each do |identifier|
          next if ns.canonical_issuer.issued.include?(identifier)
          temporary_issuer = IdentifierIssuer.new("b")
          temporary_issuer.issue_identifier(identifier)
          log_debug("          - identifier") {identifier.id}
          hash_path_list << log_depth(depth: 12) {ns.hash_n_degree_quads(identifier, temporary_issuer)}
        end

        # Create canonical replacements for nodes
        log_debug("      ca.5.3:") unless hash_path_list.empty?
        log_debug("        log point", "Canonical identifiers for temporary identifiers (4.5.3 (5.3)).")
        log_debug("        issuer:") unless hash_path_list.empty?
        hash_path_list.sort_by(&:first).each do |result, issuer|
          issuer.issued.each do |node|
            id = ns.canonical_issuer.issue_identifier(node)
            log_debug("          - blank node") {node.id}
            log_debug("            canonical identifier", id)
          end
        end
      end

      # Step 6: Yield statements using BNodes from canonical replacements
      if block_given?
        dataset.each_statement do |statement|
          if statement.has_blank_nodes?
            quad = statement.to_quad.compact.map do |term|
              term.node? ? RDF::Node.intern(ns.canonical_issuer.identifier(term)) : term
            end
            block.call RDF::Statement.from(quad)
          else
            block.call statement
          end
        end
      end

      log_debug("ca.6:")
      log_debug("  log point", "Issued identifiers map (4.4.3 (6)).")
      log_debug("  issued identifiers map: #{ns.canonical_issuer.inspect}")
      dataset
    end

  private

    class NormalizationState
      include RDF::Util::Logger

      attr_accessor :bnode_to_statements
      attr_accessor :hash_to_bnodes
      attr_accessor :canonical_issuer
      attr_accessor :max_calls
      attr_accessor :total_calls

      def initialize(**options)
        @options = options
        @bnode_to_statements, @hash_to_bnodes, @canonical_issuer = {}, {}, IdentifierIssuer.new("c14n")
        @max_calls, @total_calls = nil, 0
      end

      def add_statement(node, statement)
        bnode_to_statements[node] ||= []
        bnode_to_statements[node] << statement unless bnode_to_statements[node].any? {|st| st.eql?(statement)}
      end

      def add_bnode_hash(node, hash)
        hash_to_bnodes[hash] ||= []
        # Match on object IDs of nodes, rather than simple node equality
        hash_to_bnodes[hash] << node unless hash_to_bnodes[hash].any? {|n| n.eql?(node)}
      end

      # This algorithm calculates a hash for a given blank node across the quads in a dataset in which that blank node is a component. If the hash uniquely identifies that blank node, no further examination is necessary. Otherwise, a hash will be created for the blank node using the algorithm in [4.9 Hash N-Degree Quads](https://w3c.github.io/rdf-canon/spec/#hash-nd-quads) invoked via [4.5 Canonicalization Algorithm](https://w3c.github.io/rdf-canon/spec/#canon-algorithm).
      #
      # @param [RDF::Node] node The reference blank node identifier
      # @return [String] the SHA256 hexdigest hash of statements using this node, with replacements
      def hash_first_degree_quads(node)
        nquads = bnode_to_statements[node].
          map do |statement|
            quad = statement.to_quad.map do |t|
              case t
              when node then RDF::Node("a")
              when RDF::Node then RDF::Node("z")
              else t
              end
            end
            RDF::Statement.from(quad).to_nquads
          end
        log_debug("log point", "Hash First Degree Quads function (4.7.3).")
        log_debug("nquads:")
        nquads.each do |q|
          log_debug {"  - #{q.strip}"}
        end

        result = hexdigest(nquads.sort.join)
        log_debug("hash") {result}
        result
      end

      # @param [RDF::Node] related
      # @param [RDF::Statement] statement
      # @param [IdentifierIssuer] issuer
      # @param [String] position one of :s, :o, or :g
      # @return [String] the SHA256 hexdigest hash
      def hash_related_node(related, statement, issuer, position)
        log_debug("related") {related.id}
        input = "#{position}"
        input << statement.predicate.to_ntriples unless position == :g
        if identifier = (canonical_issuer.identifier(related) ||
                         issuer.identifier(related))
          input << "_:#{identifier}"
        else
          log_debug("h1dq:")
          input << log_depth(depth: 2) do
            hash_first_degree_quads(related)
          end
        end
        log_debug("input") {input.inspect}
        log_debug("hash") {hexdigest(input)}
        hexdigest(input)
      end

      # @param [RDF::Node] node
      # @param [IdentifierIssuer] issuer
      # @return [Array<String,IdentifierIssuer>] the Hash and issuer
      # @raise [RuntimeError] If total number of calls has exceeded `max_calls` times the number of blank nodes in the dataset.
      def hash_n_degree_quads(node, issuer)
        log_debug("hndq:")
        log_debug("  log point", "Hash N-Degree Quads function (4.9.3).")
        log_debug("  identifier") {node.id}
        log_debug("  issuer") {issuer.inspect}

        if max_calls && total_calls >= max_calls
          raise "Exceeded maximum number of calls (#{total_calls}) allowed to hash_n_degree_quads"
        end
        @total_calls += 1

        # hash to related blank nodes map
        hn = {}

        log_debug("  hndq.2:")
        log_debug("    log point", "Quads for identifier (4.9.3 (2)).")
        log_debug("    quads:")
        bnode_to_statements[node].each do |s|
          log_debug {"    - #{s.to_nquads.strip}"}
        end

        # Step 3
        log_debug("  hndq.3:")
        log_debug("    log point", "Hash N-Degree Quads function (4.9.3 (3)).")
        log_debug("    with:") unless bnode_to_statements[node].empty?
        bnode_to_statements[node].each do |statement|
          log_debug {"      - quad: #{statement.to_nquads.strip}"}
          log_debug("        hndq.3.1:")
          log_debug("          log point", "Hash related bnode component (4.9.3 (3.1))")
          log_depth(depth: 10) {hash_related_statement(node, statement, issuer, hn)}
        end
        log_debug("    Hash to bnodes:")
        hn.each do |k,v|
          log_debug("      #{k}:")
          v.each do |vv|
            log_debug("        - #{vv.id}")
          end
        end

        data_to_hash = ""

        # Step 5
        log_debug("  hndq.5:")
        log_debug("    log point", "Hash N-Degree Quads function (4.9.3 (5)), entering loop.")
        log_debug("    with:")
        hn.keys.sort.each do |hash|
          log_debug("      - related hash", hash)
          log_debug("        data to hash") {data_to_hash.to_json}
          list = hn[hash]
          # Iterate over related nodes
          chosen_path, chosen_issuer = "", nil
          data_to_hash += hash

          log_debug("        hndq.5.4:")
          log_debug("          log point", "Hash N-Degree Quads function (4.9.3 (5.4)), entering loop.")
          log_debug("          with:") unless list.empty?
          list.permutation do |permutation|
            log_debug("          - perm") {permutation.map(&:id).to_json(indent: ' ', space: ' ')}
            issuer_copy, path, recursion_list = issuer.dup, "", []

            log_debug("            hndq.5.4.4:")
            log_debug("              log point", "Hash N-Degree Quads function (4.9.3 (5.4.4)), entering loop.")
            log_debug("              with:")
            permutation.each do |related|
              log_debug("                - related") {related.id}
              log_debug("                  path") {path.to_json}
              if canonical_issuer.identifier(related)
                path << '_:' + canonical_issuer.issue_identifier(related)
              else
                recursion_list << related if !issuer_copy.identifier(related)
                path << '_:' + issuer_copy.issue_identifier(related)
              end

              # Skip to the next permutation if chosen path isn't empty and the path is greater than the chosen path
              break if !chosen_path.empty? && path.length >= chosen_path.length
            end

            log_debug("            hndq.5.4.5:")
            log_debug("              log point", "Hash N-Degree Quads function (4.9.3 (5.4.5)), before possible recursion.")
            log_debug("              recursion list") {recursion_list.map(&:id).to_json(indent: ' ')}
            log_debug("              path") {path.to_json}
            log_debug("              with:") unless recursion_list.empty?
            recursion_list.each do |related|
              log_debug("                - related") {related.id}
              result = log_depth(depth: 18) do
                hash_n_degree_quads(related, issuer_copy)
              end
              path << '_:' + issuer_copy.issue_identifier(related)
              path << "<#{result.first}>"
              issuer_copy = result.last
              log_debug("                  hndq.5.4.5.4:") 
              log_debug("                    log point", "Hash N-Degree Quads function (4.9.3 (5.4.5.4)), combine result of recursion.")
              log_debug("                    path") {path.to_json}
              log_debug("                    issuer copy") {issuer_copy.inspect}
              break if !chosen_path.empty? && path.length >= chosen_path.length && path > chosen_path
            end

            if chosen_path.empty? || path < chosen_path
              chosen_path, chosen_issuer = path, issuer_copy
            end
          end

          data_to_hash += chosen_path
          log_debug("        hndq.5.5:")
          log_debug("          log point", "Hash N-Degree Quads function (4.9.3 (5.5). End of current loop with Hn hashes.")
          log_debug("          chosen path") {chosen_path.to_json}
          log_debug("          data to hash") {data_to_hash.to_json}
          issuer = chosen_issuer
        end

        log_debug("  hndq.6:")
        log_debug("    log point", "Leaving Hash N-Degree Quads function (4.9.3).")
        log_debug("    hash") {hexdigest(data_to_hash)}
        log_depth(depth: 4) {log_debug("issuer") {issuer.inspect}}
        return [hexdigest(data_to_hash), issuer]
      end

      def inspect
        "NormalizationState:\nbnode_to_statements: #{inspect_bnode_to_statements}\nhash_to_bnodes: #{inspect_hash_to_bnodes}\ncanonical_issuer: #{canonical_issuer.inspect}"
      end

      def inspect_bnode_to_statements
        bnode_to_statements.map do |n, statements|
          "#{n.id}: #{statements.map {|s| s.to_nquads.strip}}"
        end.join(", ")
      end

      def inspect_hash_to_bnodes
      end

      protected

      def hexdigest(val)
        Digest::SHA256.hexdigest(val)
      end

      # Group adjacent bnodes by hash
      def hash_related_statement(node, statement, issuer, map)
        log_debug("with:") if statement.to_h.values.any? {|t| t.is_a?(RDF::Node)}
        statement.to_h(:s, :p, :o, :g).each do |pos, term|
          next if !term.is_a?(RDF::Node) || term == node

          log_debug("  - position", pos)
          hash = log_depth(depth: 4) {hash_related_node(term, statement, issuer, pos)}
          map[hash] ||= []
          map[hash] << term unless map[hash].any? {|n| n.eql?(term)}
        end
      end
    end

    class IdentifierIssuer 
      def initialize(prefix = "c14n")
        @prefix, @counter, @issued = prefix, 0, {}
      end

      # Return an identifier for this BNode
      # @param [RDF::Node] node
      # @return [String] Canonical identifier for node
      def issue_identifier(node)
        @issued[node] ||= begin
          res, @counter = @prefix + @counter.to_s, @counter + 1
          res
        end
      end

      def issued
        @issued.keys
      end

      # @return [RDF::Node] Canonical identifier assigned to node
      def identifier(node)
        @issued[node]
      end

      # @return [Hash{Symbol => Symbol}] the issued identifiers map
      def to_hash
        @issued.inject({}) {|memo, (node, canon)| memo.merge(node.id => canon)}
      end

      # Duplicate this issuer, ensuring that the issued identifiers remain distinct
      # @return [IdentifierIssuer]
      def dup
        other = super
        other.instance_variable_set(:@issued, @issued.dup)
        other
      end

      def inspect
        "{#{@issued.map {|k,v| "#{k.id}: #{v}"}.join(', ')}}"
      end
    end
  end
end
