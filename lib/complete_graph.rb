class CompleteGraph
  
  attr_accessor :nodes
  attr_accessor :adjacencies
  
  def initialize(nodes)
    self.nodes = nodes
    
    self.adjacencies = {}.tap do |collection|
      nodes.each { |node| collection[node] = nodes - [node] }
    end
  end
end
