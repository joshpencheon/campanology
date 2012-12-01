class ExtentChecker

  attr_accessor :rows

  def initialize(extent)
    self.rows = parse_rows(extent.is_a?(Array) ? extent : extent.rows)
  end

  def check
    valid = true
    rows.each_with_index do |row, index|
      if index + 1 < rows.length
        valid &&= proof(row, rows[index + 1])
      end
    end
    
    # Check we can complete the loop:
    valid &&= proof(rows.last, rows.first)
  end
  
  private
  
  def proof(row_a, row_b)    
    valid = true
    row_a.each_with_index do |bell, index|
      shift = (index - row_b.index(bell)).abs
      
      valid = false if shift > 1
    end
    
    valid
  end
  
  def parse_rows(rows)
    rows.map do |row|
      row.is_a?(Array) ? row : row.to_s.split(//).map(&:to_i)
    end
  end

end