class ChangeFinder
  
  attr_accessor :n
  
  def self.count_for(bell_count)
    if bell_count < 2 then 0
    elsif bell_count == 2 then 1
    else 
      2 + 2 * count_for(bell_count - 2) + count_for(bell_count - 3)
    end
  end
  
  def initialize(bell_count)
    self.n = bell_count
  end
  
  def valid_changes
    case n
    when 0 then []
    when 1 then []
    when 2 then [ [1,2] ]
    else
      n_minus_2 = self.class.new(n - 2)
      n_minus_3 = self.class.new(n - 3)
      
      n_minus_2.valid_changes + n_minus_2.with_identity.map { |change|
        change + [n - 1, n]
      } + n_minus_3.with_identity.map { |change|
        change + [n - 2, n - 1]        
      } 
    end
  end
  
  def valid_changes_in_notation
    base_string = (1..n).to_a.join
  
    changes = valid_changes.map do |swap|
      swap.delete(0) # Remove placeholder identity element if present
      notation = base_string.gsub(Regexp.new(swap.join('|')), '')  
      
      notation.blank? ? 'x' : notation
    end
  end
    
  def with_identity
    valid_changes + [ [0] ]
  end
end