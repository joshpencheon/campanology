class CircuitFinder
  
  attr_accessor :graph
  
  def initialize(graph)
    puts "CF init with #{graph.nodes.length} nodes and #{graph.edges.length} edges"

    odd_nodes = graph.nodes.select { |node| graph.edges_for(node).length % 2 == 1 }

    if odd_nodes.any?
      odd_nodes.each do |node|
        puts node.inspect
        puts graph.edges_for(node).inspect
      end
      raise ArgumentError, "Not all vertices have even degree!"
    end

    self.graph = graph
  end
  
  def seek!
    visited_nodes = [ graph.nodes.first ]
    
    while visited_nodes.count(visited_nodes.first) == 1
      candidates = graph.connected_to(visited_nodes.last) - visited_nodes
      # Allow loop back as a last resort, if it would be possible:
      candidates << visited_nodes.first if graph.connected?(visited_nodes.first, visited_nodes.last)
      puts "candidates for #{visited_nodes.last}: #{candidates.inspect}"      
      visited_nodes << candidates.first if candidates.any?
      puts "added node, path now has length: #{visited_nodes.length} - last: #{visited_nodes.last}. #{graph.connected?(*visited_nodes[-2,2])} #{graph.connected?(*visited_nodes[-2,2].reverse)}"
    end
    
    if visited_nodes.length - 1 == graph.nodes.length
      visited_nodes.pop
      return visited_nodes
    else
      while visited_nodes.length < graph.nodes.length
        puts "starting loop, got #{visited_nodes.length}"
        
        visited_nodes.each_with_index do |node, index|
          unvisited_nodes_from_here = graph.connected_to(node) - visited_nodes
        
          if unvisited_nodes_from_here.any?
            puts "got unvisited_nodes from here"
            reduced_nodes = graph.nodes - visited_nodes + [node]
            reduced_edges = graph.edges_for(reduced_nodes)

            sub_graph = WeightedGraph.new(reduced_nodes, reduced_edges)
            sub_circuit = CircuitFinder.new(sub_graph).seek!
          
            visited_nodes = visited_nodes[0..(index-1)] + sub_circuit + visited_nodes[index..-1]
          
            break
          end
        end
      end
      
      visited_nodes
    end
  end
  
  
end