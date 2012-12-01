class Node
  
  attr_accessor :connections
  attr_accessor :label
  
  def initialize(label)
    self.label = label.to_s
    self.connections = {}
  end

  def degree
    connections.values.flatten.length
  end
  
  def connect(other_node, distance = 1)
    connections[other_node] ||= []
    connections[other_node] << distance
  end
  
  def disconnect(other_node)
    connections.delete(other_node)
  end
  
  def connected?(other_node)
    connections.key?(other_node)
  end
  
  def distance_between(other_node)
    if conneected?(other_node)
      connections[other_node].min
    else
      0
    end
  end
  
  def to_s
    label
  end
  
end