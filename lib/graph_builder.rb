class GraphBuilder
  
  attr_accessor :nodes
  attr_accessor :changes
  attr_accessor :adjacencies
  
  def initialize(n, changes)
    self.changes = changes
    size = (1..n).to_a.inject(1, :*)
    # self.adjacencies = Matrix.build(size) { 0 }
    self.adjacencies = Hash.new { |hash, key| hash[key] = [] }    
    self.nodes = [ ]
    attach_node((1..n).to_a)
  
    puts self.adjacencies.map { |k, v| v.length }.inject(0, &:+)
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
  
  def attach_node(row)
    if !self.nodes.include?(row)
      insertion_index = self.nodes.length
      
      self.nodes << row
      apply_changes(row).each do |new_row| 
        connect(row, new_row)
        attach_node(new_row) 
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