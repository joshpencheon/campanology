class Node
  
  attr_accessor :connections
  attr_accessor :label
  
  def initialize(label)
    self.label = label.to_s
    reset_connections!
  end

  def inititialize_copy(original)
    super
    @connections = @connections.dup
    @label       = @label.dup
  end
  
  def merge!(other_node, context)
    other_node.connections.each do |node, distances|
      proxy = context.get_node(node)
      distances.each { |dist| connect(proxy, dist) }
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
      (connections[other_node] || []).delete(distance)
    else
      connections.delete(other_node)
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
    
end