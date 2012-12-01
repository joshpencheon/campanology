require_relative 'node'

class WeightedGraph
  
  attr_accessor :nodes
  attr_accessor :edges
  
  def self.combine(graph1, graph2)        
    new(graph1.nodes | graph2.nodes, graph1.edges + graph2.edges)
  end
  
  def initialize(nodes, edges = [])
    self.nodes = nodes
    
    nodes.each(&:reset_connections!) if edges.any?
    edges.each do |edge|
      node1, distance, node2 = edge
      connect!(node1, node2, distance)
    end
  end
  
  def edges
    nodes.combination(2).map { |pair|
      node1, node2 = pair
      node1.connected?(node2) ? edge_for(node1, node2) : nil
    }.compact
  end
    
  def clone
    WeightedGraph.new(nodes.clone, edges.clone)
  end
  
  def build_sub_graph(edge_list)    
    sub_graph = WeightedGraph.new(self.nodes.map { |n| Node.new(n) })
        
    edge_list.each do |connection|
      node1, node2 = connection.map { |i| nodes[i-1] }
      sub_graph.connect!(sub_graph.get_node(node1), sub_graph.get_node(node2), node1.distance_between(node2))
    end
    
    sub_graph
  end
  
  def to_dimacs(filename) 
    path = File.join(File.dirname(__FILE__), "..", "#{filename}")
    File.open(path, 'w') do |file|
      file.write("c WeightedGraph.rb output at #{Time.now} \n")
      file.write("p edge #{nodes.length} #{edges.length} \n")
      
      edge_array.each { |edge| file.write('e ' + edge.join(' ') + "\n") }
    end
    
    path
  end
  
  # Implementing Prim's Aglorithm for finding MST
  def minimum_spanning_tree(known_weights)
    starting_node = Node.new(nodes.first.label)
    tree = WeightedGraph.new([ starting_node ])
    
    candidates = nodes.first.connected_nodes.map { |n| [ nodes.first, n, n.distance_between(nodes.first) ] }
    
    while tree.nodes.length < nodes.length
      print "#{tree.nodes.length}"

      next_edge = nil
      known_weights.each do |weight|
          next_edge = candidates.detect { |edge| edge.last == weight }
          break if next_edge
      end
      
      connected_existing_node, connected_new_node, distance = next_edge      
      
      new_node      = Node.new(connected_new_node) 
      existing_node = tree.get_node(connected_existing_node)
      
      tree.nodes << new_node
            
      tree.connect!(existing_node, new_node, distance)
      
      print '.'
      $stdout.flush
      
      
      # Remove edges that would now create cycles:
      dropping = tree.nodes.map do |node|
        connected_node = get_node(node)
        [ connected_node, connected_new_node, connected_new_node.distance_between(connected_node) ]
      end
      candidates -= dropping

      print '.'
      $stdout.flush
      
      # Add unlocked edges:
      connected_new_node.connected_nodes.each do |node|
        candidates << [ connected_new_node, node, node.distance_between(connected_new_node) ] unless tree.nodes.index(tree.get_node(node))
      end

      print '.  '
      $stdout.flush      
      
    end
    
    tree
  end

  # def minimum_spanning_tree
  #   tree_nodes = [ nodes.first.clone ]
  #   pairs = []
  #   while tree_nodes.length < nodes.length
  #     best_nodes = tree_nodes.map do |tree_node|
  #       candidates   = tree_node.connected_nodes.reject { |n| tree_nodes.index(n) }
  #       closest_node = candidates.inject do |closest, node| 
  #         tree_node.distance_between(closest) < tree_node.distance_between(node) ? closest : node
  #       end
  #       closest_node ? [ tree_node, closest_node ] : nil
  #     end
  #     
  #     next_pair = best_nodes.compact.inject do |best, pair|
  #       best.first.distance_between(best.last) < pair.first.distance_between(pair.last) ? best : pair
  #     end
  #     
  #     pairs << next_pair
  #     existing_node, new_node = next_pair
  #     tree_nodes << new_node.clone
  #     
  #     connected_to_existing = pairs.map do |pair|
  #       case existing_node
  #       when pair.first then pair.last
  #       when pair.last then pair.first
  #       else nil
  #       end
  #     end
  #     existing_node.keep_connections(connected_to_existing.compact)  
  #   end
  # 
  #   WeightedGraph.new(tree_nodes)
  # end
    # 
    # # Implementing Prim's Algorithm for finding MST
    # def minimum_spanning_tree
    #   
    #   1/0 # broken
    #   tree_nodes = [ nodes.first ]
    #   tree_edges = []
    #   
    #   available_edges = edges.select { |edge|
    #     (tree_nodes.index(edge.first) && !tree_nodes.index(edge.last)) || 
    #       (!tree_nodes.index(edge.first) && tree_nodes.index(edge.last))
    #   }
    #   
    #   while tree_nodes.length < nodes.length
    #     
    #     print "#{tree_nodes.length} "
    #     
    #     # Find best edge:            
    #     new_edge = available_edges.inject do |best_edge, edge|
    #       best_edge[1] < edge[1] ? best_edge : edge
    #     end
    #     tree_edges << new_edge
    #     
    #     # Identify new node:
    #     new_node = tree_nodes.index(new_edge[0]) ? new_edge[2] : new_edge[0]
    #     tree_nodes << new_node
    #     
    #     # remove useless edges:
    #     available_edges.reject! do |edge|
    #       edge.first == new_node || edge.last == new_node
    #     end
    #     
    #   end
    #   
    #   puts "MST: got #{tree_nodes.length} nodes before dedup."
    #   puts "dups:", tree_nodes.select {|n| tree_nodes.count(n) > 1}.uniq.inspect
    #   puts "MST: after uniq got: #{tree_nodes.uniq.length}"
    #   
    #   WeightedGraph.new(tree_nodes.uniq, tree_edges)
    # end
  
  def connect!(node1, node2, distance)
    raise ArgumentError, "#{node1} #{node2} distance must be positive [not #{distance}]" unless distance > 0
        
    node1.connect(node2, distance)
    node2.connect(node1, distance)    
  end
  
  def complete!(&block)
    nodes.each do |node1|
      (nodes - [node1]).each do |node2|
        connect!(node1, node2, block.call(node1, node2)) unless node1.connected?(node2)
      end
    end
  end
      
  def edges_for(node)
    if node.is_a?(Array)
      node.map { |n| edges_for(n) }.flatten
    else
      node.connected_nodes.map { |other_node| edge_for(node, other_node) }
    end
  end
  
  # Remove ALL instances of _edge_ from (multi)graph.
  def drop_edge(edge)
    node1, distance, node2 = edge
    
    node1.disconnect(node2, distance)
    node2.disconnect(node1, distance)
    
    puts "edge dropped: [#{node1}<->#{node2}][d:#{distance}]; #{self.edges.length} remaining"
  end
  
  def get_node(label)
    nodes.find { |n| n.label == label.to_s }
  end
  
  private
  
  def edge_for(node1, node2)
    [ node1, node1.distance_between(node2), node2 ]
  end
  
  def edge_array    
    edges.map { |edge| [nodes.index(edge[0]) + 1, nodes.index(edge[2]) + 1, edge[1]] }
  end
      
end

# class WeightedGraph
#   
#   attr_accessor :nodes
#   attr_accessor :edges
#   
#   def self.combine(graph1, graph2)        
#     new(graph1.nodes | graph2.nodes, graph1.edges + graph2.edges)
#   end
#   
#   def initialize(nodes, edges = [])
#     self.nodes = nodes
#     self.edges = edges
#   end
#   
#   def clone
#     WeightedGraph.new(nodes.clone, edges.clone)
#   end
#   
#   def build_sub_graph(edge_list)    
#     sub_graph = WeightedGraph.new(self.nodes)
#         
#     edge_list.each do |connection|
#       node1, node2 = connection.map { |i| nodes[i-1] }
#       sub_graph.connect!(node1, node2, distance_between(node1, node2))
#     end
#     
#     sub_graph
#   end
#   
#   def to_dimacs(filename) 
#     path = File.join(File.dirname(__FILE__), "..", "#{filename}")
#     File.open(path, 'w') do |file|
#       file.write("c WeightedGraph.rb output at #{Time.now} \n")
#       file.write("p edge #{nodes.length} #{edges.length} \n")
#       
#       edge_array.each { |edge| file.write('e ' + edge.join(' ') + "\n") }
#     end
#     
#     path
#   end
#   
#   # Implementing Prim's Algorithm for finding MST
#   def minimum_spanning_tree
#     
#     # 1/0 # broken
#     tree_nodes = [ nodes.first ]
#     tree_edges = []
#     
#     available_edges = edges.select { |edge|
#       (tree_nodes.index(edge.first) && !tree_nodes.index(edge.last)) || 
#         (!tree_nodes.index(edge.first) && tree_nodes.index(edge.last))
#     }
#     
#     while tree_nodes.length < nodes.length
#       
#       print "#{tree_nodes.length} "
#       
#       # Find best edge:            
#       new_edge = available_edges.inject do |best_edge, edge|
#         best_edge[1] < edge[1] ? best_edge : edge
#       end
#       tree_edges << new_edge
#       
#       # Identify new node:
#       new_node = tree_nodes.index(new_edge[0]) ? new_edge[2] : new_edge[0]
#       tree_nodes << new_node
#       
#       # remove useless edges:
#       available_edges.reject! do |edge|
#         edge.first == new_node || edge.last == new_node
#       end
#       
#     end
#     
#     puts "MST: got #{tree_nodes.length} nodes before dedup."
#     puts "dups:", tree_nodes.select {|n| tree_nodes.count(n) > 1}.uniq.inspect
#     puts "MST: after uniq got: #{tree_nodes.uniq.length}"
#     
#     WeightedGraph.new(tree_nodes.uniq, tree_edges)
#   end
#   
#   def connect!(node1, node2, distance)
#     raise ArgumentError, "distance must be positive" unless distance > 0
#     node1, node2 = [node1, node2].sort
#     edge = [node1, distance, node2]
#        
#     self.edges << edge unless edge.index(edge)
#     
#     edge
#   end
#   
#   def complete!(&block)
#     nodes.each do |node1|
#       (nodes - [node1]).each do |node2|
#         connect!(node1, node2, block.call(node1, node2)) unless connected?(node1, node2)
#       end
#     end
#   end
#   
#   def distance_between(node1, node2)
#     if connected?(node1, node2)
#       self.edges.map { |edge| edge.first == [node1, node2].min ? edge[1] : nil }.compact.min
#     else
#       raise ArgumentError, "Nodes not connected! (#{node1} <-/-> #{node2})"
#     end
#   end
#   
#   def connected_to(node)
#     self.edges.map { |edge| edge.first == node ? edge.last : (edge.last == node ? edge.first : nil) }.compact
#   end
#   
#   def edges_for(nodes)
#     if nodes.is_a?(Array) && nodes.first.is_a?(Array)
#       self.edges.select { |edge| nodes.index(edge.first) || nodes.index(edge.last) }
#     else
#       self.edges.select { |edge| edge.first == nodes || edge.last == nodes }
#     end
#   end
#   
#   # Remove ALL instances of _edge_ from (multi)graph.
#   def drop_edge(edge)
#     self.edges.delete(edge) while self.edges.count(edge) > 0
#     
#     puts "edge dropped: [#{edge[0].join}<->#{edge[2].join}]; #{self.edges.length} remaining"
#   end
#     
#   def connected?(node1, node2)
#     !! connected_to(node1).index(node2)
#   end
#   
#   private
#   
#   def edge_array    
#     edges.map { |edge| [nodes.index(edge[0]) + 1, nodes.index(edge[2]) + 1, edge[1]] }
#   end
#       
# end