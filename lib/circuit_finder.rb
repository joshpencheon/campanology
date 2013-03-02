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
    
    # puts tour.nodes.select { |node| node.degree % 2 == 1 }.map(&:to_s)
    # A new graph, with the nodes ordered in an Eulerian tour:
    # tour.nodes
    
    tour
  end
  
  private  
   
  def seek_from(node, path, previous_node = nil)
    add_node_to_path(previous_node, node, path)
        
    next_nodes = path.nodes.last ? graph.get_node(path.nodes.last).connected_nodes : []
    
    if next_nodes.any?
      min_distance = graph.get_node(node).connections.values.flatten.min
      other_node, distances = graph.get_node(node).connections.detect {|other, dists| dists.include?(min_distance) }
        
      count = distances.length  
        
      if count == 2
        add_node_to_path(node, other_node, path)
        
        path = seek_from(node, path, other_node)
      elsif count == 1
        path = seek_from(other_node, path, node)
      else
        raise "very multigraph - unsupported!"
      end 
    else
      puts "got loop of length #{path.nodes.length - 1}"
      path.nodes.pop
      path = extrude_path(path)
    end
        
    path
  end
  
  def add_node_to_path(previous_node, node, path)
    if new_node = path.get_node(node)
      # Do nothing!
      puts "existing node: #{node} [deg = #{new_node.degree}]"
    else
      puts "new node: #{node}"

      new_node = Node.new(node.to_s)
      path.nodes.push(new_node)      
    end
    
    if previous_node
      node          = graph.get_node(node)
      previous_node = graph.get_node(previous_node)
      
      # We have to use the original graph as the distance will have been otherwise lost
      # if this is a secondary visit to a multiedge.
      dist = original_graph.get_node(node).distance_between(original_graph.get_node(previous_node))
            
      path.connect!(new_node, path.get_node(previous_node), dist)
      graph.disconnect!(node, previous_node) 
    end
    
    new_node
  end
  
  def extrude_path(path)    
    path.nodes.each_with_index do |node, index|      
      if graph.get_node(node).degree > 0
        extrusion = seek_from(node, WeightedGraph.new([]))
        merge_paths(path, extrusion)
      end
    end

    path
  end
  
  private
  
  def merge_paths(keeping, discarding)
    discarding.nodes.each do |temp_node|
      keeping.nodes.push(Node.new(temp_node)) unless keeping.get_node(temp_node)      
      
      temp_node.connected_nodes.each do |other_temp|
        keeping.nodes.push(Node.new(other_temp)) unless keeping.get_node(other_temp)      
        
        dist = temp_node.distance_between(other_temp)                
        keeping.connect!(keeping.get_node(temp_node), keeping.get_node(other_temp), dist)
      end
    end
    
    keeping
  end
end