class CircuitFinder
  
  attr_accessor :graph
  attr_accessor :backup_graph
  
  def initialize(graph)
    self.backup_graph = graph
    self.graph = graph.clone
  end
  
  def seek!        
    tour = []
    seek_from(graph.nodes.first, tour)
        
    puts "checking connections..."
    tour.each_with_index do |v, i|
      index = (i + 1) % tour.length
      if !backup_graph.connected?(v, tour[index])
        puts "#{i} FAIL: #{v} <-/-> #{tour[index]}, #{index}, #{tour.length}"
      end
    end
    
    tour
  end
  
  private  
    
  def seek_from(node, path)    
    next_nodes = graph.connected_to(path.last)
    
    if next_nodes.any?
      count_map = graph.edges_for(node).inject({}) do |hash, edge|
        hash[edge] ||= 0
        hash[edge] += 1
        hash 
      end
          
      edge, count = count_map.first
      other_node = edge[0] == node ? edge[2] : edge[0]
          
      graph.drop_edge(edge)
          
      if count == 2
        path.push(other_node)
        path = seek_from(node, path)
      elsif count == 1
        path = seek_from(other_node, path)
      else
        raise "very multigraph - unsupported!"
      end
          
    else
      path.pop
      path = extrude_path(path)
    end
        
    path
  end
  
  def extrude_path(path)    
    path.each_with_index do |node, index|
      if graph.edges_for(node).length > 0
        path.insert(index, *seek_from(node, []))
      end
    end

    path
  end
end