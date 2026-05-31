class Ldpath::Loaders::Graph
  def initialize(graph:)
    @graph = graph
  end

  def load(uri)
    @graph
  end
end
