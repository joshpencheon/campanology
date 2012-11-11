class WeightedGraph
  
  attr_accessor :nodes
  attr_accessor :adjacencies
  
  def initialize(nodes, adjacencies)
    self.nodes = nodes
    self.adjacencies = adjacencies
  end
  
  # Implementing Prim's Algorithm for finding MST
  def minimum_spanning_tree
    tree_nodes = [ nodes.first ]
    tree_adjacencies = {}
    
    while tree_nodes.length < nodes.length      
      candidates = {}.tap do |hash|
        tree_nodes.each do |node|  
          adjacencies[node].each do |other_node, distance|
            hash[distance] = [node, other_node] unless tree_nodes.index(other_node)
          end
        end
      end
      
      first_node, second_node = candidates[candidates.keys.min]

      tree_nodes << second_node
      tree_adjacencies[first_node] ||= {}
      tree_adjacencies[first_node][second_node] = distance_between(first_node, second_node)
    end
    
    WeightedGraph.new(tree_nodes, tree_adjacencies)
  end
  
  private
  
  def connected_to(node)
    adjacencies[node].keys
  end
  
  def connected?(node1, node2)
    connected_to(node1).index(node2)
  end
  
  def distance_between(node1, node2)
    if connected?(node1, node2)
      adjacencies[node1][node2]
    else
      raise ArgumentError, "Nodes not connected!"
    end
  end
  
end