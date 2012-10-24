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
    results = {}
    self.nodes.each { |node| results[node] = seek_from_node(node) }
    
    results.each do |node, output|
      puts "From #:#{self.nodes.index(node)} #{node.inspect}, got '#{output.first}', length #{output.last.length}", true
    end
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
  
  def seek_from_node(starting_node)
    puts "seek started..."
    
    # -- PART I --  (starting from one node for now...)  
    visited_nodes = grow_basic_path([ starting_node ])
    
    # puts "DEBUG: ADJ: #{self.adjacencies.inspect}"
    # puts "DEBUG: nodes connected to first: #{connected_to(nodes.first).inspect}"
    
    puts "got basic path of length #{visited_nodes.length}, moving on to IIa)..."
    
    # -- PART II a) --
    if visited_nodes.length < nodes.length
      target_nodes = extract_target_nodes_from_path(visited_nodes)
      
      while target_nodes.length > 0
        puts "TNL: #{target_nodes.length}"
        visited_nodes = restructure_path(visited_nodes, target_nodes)
        target_nodes = extract_target_nodes_from_path(visited_nodes)
      end
    end
    
    puts "...done, moving on to IIb)..."
    
    # -- PART II b) --
    if visited_nodes.length < nodes.length
      visited_nodes = trim_and_extend_path(visited_nodes)
    end
    
    puts "...done, moving on to IIc)..."
    
    # -- PART II c) --
    if visited_nodes.length < nodes.length
      visited_nodes = trim_and_extend_path(visited_nodes.reverse)
    end
    
    # -- PART III --
    if visited_nodes.length < nodes.length
      puts "Found path:"
      puts visited_nodes.inspect
      
      ['path', visited_nodes]
    else
      puts "Found Hamiltonian tour (no circuit check):"
      puts visited_nodes.inspect
      
      ['tour', visited_nodes]
    end
  end
  
  # def trim_and_extend_path(visited_path, unvisited_path, extension_index)
  def trim_and_extend_path(visited_nodes)    
    extended_path = []
    
    subpath = visited_nodes[0..(visited_nodes.length - 3)]
      
    extension_point = subpath.detect { |node| unvisited_neighbours_of(node, visited_nodes).length > 0 }
              
    if extension_point        
      extension_index = subpath.index(extension_point)
      puts " - got extension point: #{extension_index} out of #{visited_nodes.length}"
      
      unvisited_nodes = self.nodes - visited_nodes
      reduced_adjacencies = self.adjacencies.select { |node, connections| unvisited_nodes.include?(node) }

      outside_cycle_finder = CycleFinder.new(unvisited_nodes, reduced_adjacencies)      

      first_node = unvisited_neighbours_of(extension_point, visited_nodes).first        
      unvisited_path = outside_cycle_finder.grow_basic_path([ first_node ])
        
      # visited_nodes = trim_and_extend_path(additional_nodes, visited_nodes, extension_index)
          
      v_j = (visited_nodes & connected_to(unvisited_path.last)).detect do |node|
        j = visited_nodes.index(node)
        (j > extension_index + 1) && (j < visited_nodes.length) && 
            connected?(visited_nodes[j + 1], visited_nodes[extension_index + 1])
      end
    
      if v_j
        end_index = visited_nodes.index(v_j)
      
        extended_path += visited_nodes[0..extension_index]
        extended_path += unvisited_path
        extended_path += visited_nodes[(extension_index + 1)..end_index].reverse
        extended_path += visited_nodes[(end_index + 1)..(visited_nodes.length - 1)]
      end
    end

    if extended_path.length > visited_nodes.length
      puts " - path extended by #{extended_path.length - visited_nodes.length}"
      trim_and_extend_path(extended_path)
    else
      puts " - failed to extend, returning #{visited_nodes.length}"
      visited_nodes
    end         
  end
  
  # -- PART II a) iterator --
  def restructure_path(visited_nodes, target_nodes)    
    candidate_nodes = target_nodes.map do |target_node|
      following_node = visited_nodes[visited_nodes.index(target_node) + 1]
      
      unvisited_neighbours_of(following_node, visited_nodes).map { |neighbour|
        [ [target_node, neighbour], unvisited_neighbours_of(neighbour, visited_nodes).length ]
      }
    end.flatten(1)
    
    if candidate_nodes.length > 0            
      maximal_unvisited_count = candidate_nodes.map(&:last).max
    
      pivot_node, additional_node = candidate_nodes.rassoc(maximal_unvisited_count).first
      pivot_index = visited_nodes.index(pivot_node)
        
      visited_nodes = visited_nodes[0..pivot_index] + visited_nodes[(pivot_index + 1)..-1].reverse
      visited_nodes << additional_node
    end
    
    visited_nodes = grow_basic_path(visited_nodes)
  end
  
  def extract_target_nodes_from_path(visited_nodes)
    connected_to(visited_nodes.last).select do |node|
      i = visited_nodes.index(node) 
      i && (unvisited_neighbours_of(visited_nodes[i + 1], visited_nodes).length > 0)
    end
  end
  
  def unvisited_neighbours_of(node, visited_nodes)
    connected_to(node) - visited_nodes
  end
  
  def connected_to(node)    
    self.adjacencies[node] || []
  end
  
  def connected?(a, b)
    connected_to(a).index(b)
  end
  
  def puts(*args)
    super if args.pop == true
  end

end