module Noid
  # Minters come in two varieties: stateful and stateless. A stateless minter --
  # typically used with random rather than sequential templates, since minting
  # in a sequence requires state to know the current position in the sequence --
  # mints random identifiers and **will** mint duplicates eventually, depending
  # upon the size of the identifier space in the provided template.
  #
  # A stateful minter is a minter that has been initialized with parameters
  # reflecting its current state. (A common way to store state between mintings
  # is to call the minter `#dump` method which serializes the necessary parts of
  # minter state to a hash, which may be persisted on disk or in other
  # back-ends.) The parameters that are included are:
  #
  #  * template, a string setting the identifier pattern
  #  * counters, a hash of "buckets" each with a current and max value
  #  * seq, an integer reflecting how far into the sequence the minter is
  #  * rand, a random number generator
  #
  # Minters using random templates use a number of containers, each with a
  # similar number of identifiers to split the identifier space into manageable
  # chunks (or "buckets") and to increase the appearance of randomness in the
  # identifiers.
  #
  # As an example, let's assume a random identifier template that has 100
  # possible values. It might have 10 buckets, each with 10 identifiers that
  # look similar because they have similar numeric values. Every call to `#mint`
  # will use the random number generator stored in the minter's state to select
  # a bucket at random. Stateless minters will select a bucket at random as
  # well.
  #
  # The difference between stateless and stateful minters in this context is
  # that stateful random minters are *replayable* as long as you have persisted
  # the minter's state, which includes a random number generator part of which
  # is its original seed, which may be used over again in the future to replay
  # the sequence of identifiers in this minter
  class Minter
    attr_reader :template, :seq
    attr_writer :counters

    def initialize(options = {})
      @template = Template.new(options[:template])

      @counters = options[:counters]
      @max_counters = options[:max_counters]

      # callback when an identifier is minted
      @after_mint = options[:after_mint]

      # used for random minters
      @rand = options[:rand] if options[:rand].is_a? Random
      @rand ||= Marshal.load(options[:rand]) if options[:rand]
      @rand ||= Random.new(options[:seed] || Random.new_seed)

      # used for sequential minters
      @seq = options[:seq] || 0
    end

    ##
    # Mint a new identifier
    def mint
      n = next_in_sequence
      id = template.mint(n)
      next_sequence if random?
      @after_mint.call(self, id) if @after_mint
      id
    end

    ##
    # Reseed the RNG
    def seed(seed_number, sequence = 0)
      @rand = Random.new(seed_number)
      sequence.times { next_random }
      @rand
    end

    ##
    # Is the identifier valid under the template string and checksum?
    # @param [String] id
    # @return bool
    def valid?(id)
      template.valid?(id)
    end

    ##
    # Returns the number of identifiers remaining in the minter
    # @return [Fixnum]
    def remaining
      return Float::INFINITY if unbounded?
      template.max - seq
    end

    def next_in_sequence
      if random?
        next_random
      else
        next_sequence
      end
    end

    def next_random
      raise 'Exhausted noid sequence pool' if counters.size == 0
      i = random_bucket
      n = counters[i][:value]
      counters[i][:value] += 1
      counters.delete_at(i) if counters[i][:value] == counters[i][:max]
      n
    end

    def next_sequence
      seq.tap { @seq += 1 }
    end

    def random_bucket
      @rand.rand(counters.size)
    end

    ##
    # Counters to use for quasi-random NOID sequences
    def counters
      return @counters if @counters
      return [] unless random?

      percounter = template.max / (@max_counters || Noid::MAX_COUNTERS) + 1
      t = 0
      @counters = []

      while t < template.max
        counter = {}
        counter[:value] = t
        counter[:max] = [t + percounter, template.max].min

        t += percounter

        @counters << counter
      end

      @counters
    end

    def dump
      {
        template: template.template,
        counters: Marshal.load(Marshal.dump(counters)),
        seq: seq,
        rand: Marshal.dump(@rand) # we would Marshal.load this too, but serializers don't persist the internal state correctly
      }
    end

    def random?
      template.generator == 'r'
    end

    def unbounded?
      template.generator == 'z'
    end
  end
end
