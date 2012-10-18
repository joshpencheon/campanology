class ExtentChecker

  attr_accessor :extent

  def initialize(extent)
    self.extent = extent
  end

  def check
    valid = true
    extent.rows.each_with_index do |row, index|
      if index + 1 < extent.rows.length
        valid &&= proof(row, extent.rows[index + 1])
      end
    end
    
    # Check we can complete the loop:
    valid &&= proof(extent.rows.last, extent.rows.first)
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

end