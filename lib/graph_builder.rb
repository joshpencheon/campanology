class GraphBuilder
  
  attr_accessor :size
  
  attr_accessor :nodes
  attr_accessor :changes
  attr_accessor :adjacencies
  
  def initialize(n, changes)
    self.changes = changes
    self.size = (1..n).to_a.inject(1, :*)
    # self.adjacencies = Matrix.build(size) { 0 }
    self.adjacencies = Hash.new { |hash, key| hash[key] = [] }    
    self.nodes = [ ]
    grow_from((1..n).to_a)
  end
    
  def connected?(node1, node2)
    !! self.adjacencies[node1].index(node2)
  end    
    
  private
  
  def connect(node1, node2)    
    # self.adjacencies.set(node1, node2, 1)
    # self.adjacencies.set(node2, node1, 1)
    
    # TEMP - duplicate data:
    self.adjacencies[node1] << node2
    self.adjacencies[node2] << node1
    
    self.adjacencies[node1].uniq!
    self.adjacencies[node2].uniq!
  end
  
  def add(node)
    self.nodes << node unless self.nodes.include?(node)
  end
  
  #  1: public void DfsIterative(Node node) {
  #  2:   var trail = new Stack<Transition>();
  #  3:   DoSomethingWithNode(node);
  #  4:   PushAllTransitionsToStack(node, trail);
  #  5:   while(trail.Count>0) {
  #  6:     Transition t = trail.Pop();
  #  7:     Node destination = t.Destination;
  #  8:     DoSomethingWithNode(destination);
  #  9:     PushAllTransitionsToStack(destination, trail);
  # 10:   }
  # 11: }
  
  def grow_from(row)
    join_path = []
    
    # Do Something with node...
    add(row)
      
    # Push all transitions...
    apply_changes(row).each do |new_row| 
      connect(row, new_row)
      join_path << new_row unless self.nodes.include?(new_row)
    end
          
    while join_path.length > 0
      next_row = join_path.pop
      
      # Do Something with node...
      add(next_row)
      
      # Push all transitions...
      apply_changes(next_row).each do |next_new_row| 
        connect(next_row, next_new_row)
        join_path << next_new_row  unless self.nodes.include?(next_new_row)
      end 
    end
  end
  
  def apply_changes(row)
    self.changes.map { |change| apply_change(change, row) }
  end
  
  def apply_change(change, row)
    if change == 'x'      
      change = (0 == row.length % 2) ? '' : row.length.to_s
      apply_change(change, row)
    else
      fixed_indices = change.split(//).map { |i| i.to_i - 1 }
      
      return [].tap do |new_row|
        index_skew = 0
        row.each_with_index do |bell, index|
          if fixed_indices.include?(index)
            index_skew += 1
            index_skew %= 2
          
            new_row << bell
          else  
            if 0 == (index + index_skew) % 2
              new_row << row[index + 1]
            else
              new_row << row[index - 1]
            end
          end
        end
      end
        
    end
  end
  
end