require_relative 'node'

class WeightedGraph
  
  attr_accessor :nodes
  # attr_accessor :edges
  
  def self.combine(graph1, graph2) 
    node_list = graph1.nodes.clone
    
    graph2.nodes.each do |node|
      proxy = graph1.get_node(node)
      proxy ? proxy.merge!(node, graph1) : node_list << node
    end
    
    new(node_list)
  end
  
  def initialize(nodes)
    self.nodes = nodes
  end
  
  def initialize_copy(original)
    super
    @nodes = @nodes.map(&:clone)
    
    @nodes.each do |node|
      new_connections = {}
      node.connections.each { |old_node, distances| new_connections[get_node(old_node)] = distances }
      node.connections = new_connections
    end
  end
  
  def edges
    nodes.combination(2).map { |pair|
      node1, node2 = pair
      node1.connected?(node2) ? edge_for(node1, node2) : nil
    }.compact
  end
    
  def build_sub_graph(edge_list)    
    sub_graph = WeightedGraph.new(self.nodes.map { |n| Node.new(n) })
        
    edge_list.each do |connection|
      # node1, node2 = connection.map { |i| nodes[i-1] }
      node1, node2 = connection.map { |i| nodes[i] }      
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
      print "#{tree.nodes.length} " if tree.nodes.length % 10 == 0
      # Pick the first suitable edge
      next_edge = nil
      known_weights.each do |weight|
        next_edge = candidates.detect { |edge| edge.last == weight }
        break if next_edge
      end
      
      # Break it down
      connected_existing_node, connected_new_node, distance = next_edge      
      
      # Add to the tree
      new_node      = Node.new(connected_new_node) 
      existing_node = tree.get_node(connected_existing_node)
      tree.nodes << new_node
      tree.connect!(existing_node, new_node, distance)
      
      # Remove edges that would now create cycles:
      dropping = tree.nodes.map do |node|
        connected_node = get_node(node)
        [ connected_node, connected_new_node, connected_new_node.distance_between(connected_node) ]
      end
      candidates -= dropping
      
      # Add unlocked edges:
      connected_new_node.connected_nodes.each do |node|
        candidates << [ connected_new_node, node, node.distance_between(connected_new_node) ] unless tree.nodes.index(tree.get_node(node))
      end      
    end
    
    tree
  end

  def connect!(node1, node2, distance)
    raise ArgumentError, "<#{node1}> <#{node2}>: distance must be positive [not #{distance}]" unless distance > 0
        
    node1.connect(node2, distance)
    node2.connect(node1, distance)    
  end
  
  def disconnect!(node1, node2, distance = nil)    
    node1.disconnect(node2, distance)
    node2.disconnect(node1, distance)
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