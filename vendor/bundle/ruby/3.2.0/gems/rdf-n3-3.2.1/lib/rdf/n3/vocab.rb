module RDF::N3
  # @!parse
  #   # Crypto namespace
  #   class Crypto < RDF::Vocabulary; end
  const_set("Crypto", Class.new(RDF::Vocabulary("http://www.w3.org/2000/10/swap/crypto#")))
  RDF::Vocabulary.register(:crypto, Crypto)

  # @!parse
  #   # Log namespace
  #   class Log < RDF::Vocabulary; end
  const_set("Log", Class.new(RDF::Vocabulary("http://www.w3.org/2000/10/swap/log#")))
  RDF::Vocabulary.register(:log, Log)

  # @!parse
  #   # Math namespace
  #   class Math < RDF::Vocabulary; end
  const_set("Math", Class.new(RDF::Vocabulary("http://www.w3.org/2000/10/swap/math#")))
  RDF::Vocabulary.register(:math, Math)

  # @!parse
  #   # Rei namespace
  #   class Rei < RDF::Vocabulary; end
  const_set("Rei", Class.new(RDF::Vocabulary("http://www.w3.org/2000/10/swap/reify#")))
  RDF::Vocabulary.register(:rei, Rei)

  # @!parse
  #   # Str namespace
  #   class Str < RDF::Vocabulary; end
  const_set("Str", Class.new(RDF::Vocabulary("http://www.w3.org/2000/10/swap/string#")))
  RDF::Vocabulary.register(:string, Str)

  # @!parse
  #   # Time namespace
  #   class Time < RDF::Vocabulary; end
  const_set("Time", Class.new(RDF::Vocabulary("http://www.w3.org/2000/10/swap/time#")))
  RDF::Vocabulary.register(:time, Time)
end
