require_relative 'weighted_graph'

class CircuitFinder
  
  attr_accessor :graph
  attr_accessor :original_graph
  
  def initialize(graph)
    self.original_graph = graph
    self.graph = graph.dup
  end
  
  def seek!
    tour = WeightedGraph.new([])        
    seek_from(graph.nodes.first, tour)
    
    # Remove all connections:
    tour.nodes.each(&:reset_connections!)    
    
    # Connect loop:
    tour.nodes.push(tour.nodes.first)
        
    # A new graph, with the nodes ordered in an Eulerian tour:
    tour.nodes
  end
  
  private  
   
  def seek_from(node, path)        
    path.nodes.push(node)
        
    next_nodes = path.nodes.last ? path.nodes.last.connected_nodes : []
    
    if next_nodes.any?  
      other_node, distances = node.connections.first
      count = distances.length
      
      graph.disconnect!(node, other_node)
          
      if count == 2
        path.nodes.push(other_node)
        path = seek_from(node, path)
      elsif count == 1
        path = seek_from(other_node, path)
      else
        raise "very multigraph - unsupported!"
      end 
    else
      path.nodes.pop
      path = extrude_path(path)
    end
        
    path
  end
  
  def extrude_path(path)    
    path.nodes.each_with_index do |node, index|      
      if node.degree > 0
        extrusion = seek_from(node, WeightedGraph.new([]))
        path.nodes.insert(index, *extrusion.nodes)
      end
    end

    path
  end
end