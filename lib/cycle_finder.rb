class CycleFinder
  
  attr_accessor :adjacencies
  attr_accessor :nodes
  
  def initialize(nodes, adjacencies)
    self.nodes = nodes
    self.adjacencies = adjacencies
  end
  
  # Look for Hamiltonian Cycles, as described
  # here: http://www.dharwadker.org/hamilton/
  def seek!
    
    # -- PART I --    
    visited_nodes = grow_basic_path([ nodes.first ])
    
    # -- PART II a) --
    if visited_nodes.length < nodes.length
      target_nodes = extract_target_nodes_from_path(visited_nodes)
      
      while target_nodes.length > 0
        visited_nodes = restructure_path(visited_nodes, target_nodes)
        target_nodes = extract_target_nodes_from_path(visited_nodes)
      end
    end
    
    # -- PART II b) --
    if visited_nodes.length < nodes.length
      subpath = visited_nodes[0..(visited_nodes - 3)]
      
      unvisited_node = subpath.detect { |node| 
        unvisited_neighbours_of(node, visited_nodes).length > 0 
      }
            
      visited_indices = [].tap do |list|
        self.nodes.each_with_index { |node, i| list << i+1 if visited_nodes.include?(node) }
      end
      
      reduced_adjacencies = Matrix.drop(adjacencies, visited_indices)
      CycleFinder.new(nodes - visited_nodes, reduced_adjacencies)
    end
    
    
        
    
  end

  # -- PART I --
  def grow_basic_path(visited_nodes)
    current_node = visited_nodes.last
    
    while current_node && unvisited_neighbours_of(current_node, visited_nodes).length > 0
      neighbours = unvisited_neighbours_of(current_node, visited_nodes).map { |neighbour|
        [ neighbour, unvisited_neighbours_of(neighbour, visited_nodes).lenth ]
      }
      
      minimal_unvisited_count = neighbours.map(&:last).min
      current_node = neighbours.rassoc(minimal_unvisited_count).first
      
      visited_nodes << current_node
    end
    
    visited_nodes
  end
  
  private
  
  # -- PART II a) iterator --
  def restructure_path(visited_nodes, target_nodes)    
    candidate_nodes = target_nodes.map do |target_node|
      unvisited_neighbours_of(target_node, visited_nodes).map { |neighbour|
        [ [target_node, neighbour], unvisited_neighbours_of(neighbour, visited_nodes).length ]
      }
    end.flatten(1)
        
    maximal_unvisited_count = candidate_nodes.map(&:last).max
    pivot_node, additional_node = candidate_nodes.rassoc(maximal_unvisited_count).first
    pivot_index = visited_nodes.index(pivot_node)
        
    visited_nodes = visited_nodes[0..pivot_index] + visited_nodes[(pivot_index + 1)..-1].reverse
    visited_nodes << additional_node
        
    visited_nodes = grow_basic_path(visited_nodes)    
  end
  
  def extract_target_nodes_from_path(visited_nodes)
    connected_to(visited_nodes.last).select do |node|
      i = visited_nodes.index(node) 
      i && unvisited_neighbours_of(visited_nodes[i + 1], visited_nodes).length > 0
    end
  end
  
  def unvisited_neighbours_of(node, visited_nodes)
    visited_nodes - connected_to(node)
  end
  
  def connected_to(node)
    label = self.nodes.index(node)
    
    [].tap do |connections|
      self.adjacencies.column(label).to_a.each_with_index do |entry, index|
        if entry > 0
          connections << self.nodes[index]
        end
      end
    end
  end
  
end