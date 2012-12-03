class Node
  
  attr_accessor :connections
  attr_accessor :label
  
  def initialize(label)
    self.label = label.to_s        
    reset_connections!
  end
   
  def merge!(other_node, context)
    raise ArgumentError, "Cannot merge with self!" if self.equal?(other_node)
    
    other_node.connections.each do |node, distances|
      proxy = context.get_node(node)
      distances.each_with_index { |dist, index| connect(proxy, dist) }
    end
  end

  def degree
    connections.values.flatten.length
  end
  
  def connect(other_node, distance = 1)
    connections[other_node] ||= []
    connections[other_node] << distance
  end
  
  def reset_connections!
    self.connections = {}
  end
  
  def disconnect(other_node, distance = nil)
    if distance
      target = connections.find { |key, value| key.label == other_node.label }
      (target || []).delete(distance)
    else
      connections.delete_if { |key, value| key.label == other_node.label }
    end
  end
  
  def keep_connections(other_nodes)
    connections.select! { |node, dists| other_nodes.index(node) }
  end
  
  def connected?(other_node)
    connections.key?(other_node)
  end
  
  def distance_between(other_node)
    connected?(other_node) ? connections[other_node].min : 0
  end
  
  def connected_nodes
    connections.keys
  end
  
  def to_s
    label
  end
  
  def inspect
    "#{self.class}, #{self.object_id}: <#{label}>, connections: #{connections.map { |k,v| k.to_s + '->' + v.inspect }}"
  end
    
end