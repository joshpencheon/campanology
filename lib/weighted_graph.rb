class WeightedGraph
  
  attr_accessor :nodes
  attr_accessor :edges
  
  def self.combine(graph1, graph2)        
    new(graph1.nodes | graph2.nodes, graph1.edges + graph2.edges)
  end
  
  def initialize(nodes, edges = [])
    self.nodes = nodes
    self.edges = edges
  end
  
  def clone
    WeightedGraph.new(nodes.clone, edges.clone)
  end
  
  def build_sub_graph(edge_list)    
    sub_graph = WeightedGraph.new(self.nodes)
        
    edge_list.each do |connection|
      node1, node2 = connection.map { |i| nodes[i-1] }
      sub_graph.connect!(node1, node2, distance_between(node1, node2))
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
  
  # Implementing Prim's Algorithm for finding MST
  def minimum_spanning_tree
    tree_nodes = [ nodes.first ]
    tree_edges = []
    
    while tree_nodes.length < nodes.length
      # candidates = {}.tap do |hash|
      #   tree_nodes.each do |node|  
      #     connected_to(node).each do |other_node|
      #       distance = distance_between(node, other_node)
      #       hash[distance] = [node, other_node] unless tree_nodes.index(other_node)
      #     end
      #   end
      #   
      # 
      # end
      
      new_edge = edges.select { |edge|
        (tree_nodes.index(edge.first) && !tree_nodes.index(edge.last)) || 
          (!tree_nodes.index(edge.first) && tree_nodes.index(edge.last))
      }.inject do |best_edge, edge|
        best_edge[1] < edge[1] ? best_edge : edge
      end
      
      tree_edges << new_edge
      
      tree_nodes << new_edge[0] << new_edge[2]
      tree_nodes.uniq!
    end
    
    puts "MST: got #{tree_nodes.length} nodes before dedup."
    puts "dups:", tree_nodes.select {|n| tree_nodes.count(n) > 1}.uniq.inspect
    puts "MST: after uniq got: #{tree_nodes.uniq.length}"
    
    WeightedGraph.new(tree_nodes.uniq, tree_edges)
  end
  
  def connect!(node1, node2, distance)
    raise ArgumentError, "distance must be positive" unless distance > 0
    node1, node2 = [node1, node2].sort
    edge = [node1, distance, node2]
       
    self.edges << edge unless edge.index(edge)
    
    edge
  end
  
  def complete!(&block)
    nodes.each do |node1|
      (nodes - [node1]).each do |node2|
        connect!(node1, node2, block.call(node1, node2)) unless connected?(node1, node2)
      end
    end
  end
  
  def distance_between(node1, node2)
    if connected?(node1, node2)
      self.edges.map { |edge| edge.first == [node1, node2].min ? edge[1] : nil }.compact.min
    else
      raise ArgumentError, "Nodes not connected! (#{node1} <-/-> #{node2})"
    end
  end
  
  def connected_to(node)
    self.edges.map { |edge| edge.first == node ? edge.last : (edge.last == node ? edge.first : nil) }.compact
  end
  
  def edges_for(nodes)
    if nodes.is_a?(Array) && nodes.first.is_a?(Array)
      self.edges.select { |edge| nodes.index(edge.first) || nodes.index(edge.last) }
    else
      self.edges.select { |edge| edge.first == nodes || edge.last == nodes }
    end
  end
    
  def connected?(node1, node2)
    !! connected_to(node1).index(node2)
  end
  
  private
  
  def edge_array    
    edges.map { |edge| [nodes.index(edge[0]) + 1, nodes.index(edge[2]) + 1, edge[1]] }
  end
      
end