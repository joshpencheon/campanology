class CycleFinder
  
  attr_accessor :adjacencies
  attr_accessor :nodes
  
  def self.from_graph_builder(graph_builder)
    new(graph_builder.nodes, graph_builder.adjacencies)
  end
  
  def initialize(nodes, adjacencies)
    puts "initialising with #{nodes.length} nodes..."
    
    self.nodes = nodes
    self.adjacencies = adjacencies
  end
  
  # Look for Hamiltonian Cycles, as described
  # here: http://www.dharwadker.org/hamilton/
  def seek!
    puts "seek started..."
    
    # -- PART I --    
    visited_nodes = grow_basic_path([ nodes.first ])
    
    puts "got basic path, moving on to IIa)..."
    
    # -- PART II a) --
    if visited_nodes.length < nodes.length
      target_nodes = extract_target_nodes_from_path(visited_nodes)
      
      while target_nodes.length > 0
        visited_nodes = restructure_path(visited_nodes, target_nodes)
        target_nodes = extract_target_nodes_from_path(visited_nodes)
      end
    end
    
    puts "...done, moving on to IIb)..."
    
    # -- PART II b) --
    if visited_nodes.length < nodes.length
      visited_nodes = trim_and_extend_path(visited_nodes)
    end
    
    # -- PART II c) --
    if visited_nodes.length < nodes.length
      visited_nodes = trim_and_extend_path(visited_nodes.reverse)
    end
    
    # -- PART III --
    if visited_nodes.length < nodes.length
      puts "Found path:"
      puts visited_nodes.inspect
    else
      puts "Found Hamiltonian tour (no circuit check):"
      puts visited_nodes.inspect
    end
        
    # visited_nodes
  end

  # -- PART I --
  def grow_basic_path(visited_nodes)
    puts "growing basic path from #{visited_nodes.length} nodes"
    
    current_node = visited_nodes.last
    
    while current_node && unvisited_neighbours_of(current_node, visited_nodes).length > 0
      
      puts " - looping, visited #{visited_nodes.length} nodes"
      
      neighbours = unvisited_neighbours_of(current_node, visited_nodes).map { |neighbour|
        [ neighbour, unvisited_neighbours_of(neighbour, visited_nodes).length ]
      }
      
      puts " - neighbours length: #{neighbours.length}, nodes: #{self.nodes.length}, visited_nodes: #{visited_nodes.length}"
      
      minimal_unvisited_count = neighbours.map(&:last).min
      current_node = neighbours.rassoc(minimal_unvisited_count).first
      
      visited_nodes << current_node
    end
    
    visited_nodes
  end
  
  private
  
  # def trim_and_extend_path(visited_path, unvisited_path, extension_index)
  def trim_and_extend_path(visited_nodes)    
    subpath = visited_nodes[0..(visited_nodes.length - 3)]
      
    extension_point = subpath.detect { |node| 
      unvisited_neighbours_of(node, visited_nodes).length > 0 
    }
    extension_index = subpath.index(extension_point)
      
    if extension_point  
      visited_indices = [].tap do |list|
        self.nodes.each_with_index { |node, i| list << i+1 if visited_nodes.include?(node) }
      end
      reduced_adjacencies = Matrix.drop(self.adjacencies, visited_indices)
      
      unvisited_nodes = self.nodes - visited_nodes
      outside_cycle_finder = CycleFinder.new(unvisited_nodes, reduced_adjacencies)      

      first_node = unvisited_neighbours_of(extension_point, visited_nodes).first        
      unvisited_path = outside_cycle_finder.grow_basic_path([ first_node ])
        
      # visited_nodes = trim_and_extend_path(additional_nodes, visited_nodes, extension_index)
          
      v_j = (visited_nodes & connected_to(unvisited_path.last)).detect do |node|
        j = visited_nodes.index(node)
        (j > extension_index + 1) && (j < visited_nodes.length) && 
            connected?(visited_nodes[j + 1], visited_nodes[extension_index + 1])
      end
      
      extended_path = []
      if v_j
        end_index = visited_nodes.index(v_j)
      
        extended_path += visited_nodes[0..extension_index]
        extended_path += unvisited_path
        extended_path += visited_nodes[(extension_index + 1)..end_index].reverse
        extended_path += visited_nodes[(end_index + 1)..(visited_nodes.length - 1)]
      end
      
      if extended_path.length > visited_nodes.length
        trim_and_extend_path(extended_path)
      else
        visited_nodes
      end         
    end
  end
  
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
    connected_to(node) - visited_nodes
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
  
  def connected?(a, b)
    connected_to(a).index(b)
  end
  
end