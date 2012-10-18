class ExtentFinder < Extent
  
  attr_accessor :first_row
  attr_accessor :changes
  
  def initialize(first_row, changes)
    self.first_row = first_row
    self.changes = changes
  end
  
  def seek
    
  end
  
  def found?
    ExtentChecker.new(self).check
  end
  
end