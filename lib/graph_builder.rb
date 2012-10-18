class GraphBuilder
  
  attr_accessor :nodes
  attr_accessor :changes
  attr_accessor :adjacencies
  
  def initialize(n, changes)
    self.changes = changes
    
    size = (1..n).to_a.inject(1, :*)
    self.adjacencies = Matrix.build(size) { 0 }
    
    self.nodes = [ ]
    attach_node((1..n).to_a)
    
    puts (Matrix.build(1, size) { 1 } * self.adjacencies * Matrix.build(size, 1) { 1 }).inspect
  end
    
  private
  
  def connect(node1, node2)    
    self.adjacencies.set(node1, node2, 1)
    self.adjacencies.set(node2, node1, 1)
  end
  
  def attach_node(row)
    if !self.nodes.include?(row)
      insertion_index = self.nodes.length
      
      self.nodes << row
            
      new_rows = apply_changes(row)
      new_rows.map { |new_row| attach_node(new_row) }.each do |other_index|
        connect(insertion_index, other_index)
      end
      
      insertion_index
    else
      self.nodes.index(row)
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
      
      [].tap do |new_row|
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