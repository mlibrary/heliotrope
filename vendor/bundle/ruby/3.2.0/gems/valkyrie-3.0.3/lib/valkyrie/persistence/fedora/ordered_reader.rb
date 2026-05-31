# frozen_string_literal: true
module Valkyrie::Persistence::Fedora
  # Lazily iterates over a doubly linked list, fixing up nodes if necessary.
  # Used for reading ordered members out of Fedora, and then converting them to
  # member_ids.
  class OrderedReader
    include Enumerable
    attr_reader :root

    # @param root [Valkyrie::Persistence::Fedora::OrderedList]
    def initialize(root)
      @root = root
    end

    # Enumerates through each node in the RDF linked list
    # @yield [Valkyrie::Persistence::Fedora::OrderedList::HeadSentinel, Valkyrie::Persistence::Fedora::ListNode]
    def each
      proxy = first_head
      while proxy
        yield proxy unless proxy.nil?
        next_proxy = proxy.next
        next_proxy.try(:prev=, proxy) if next_proxy&.prev != proxy
        proxy = next_proxy
      end
    end

    private

    # Access the "first" (head) node for the linked list
    # @return [Valkyrie::Persistence::Fedora::OrderedList::HeadSentinel]
    def first_head
      root.head
    end
  end
end
