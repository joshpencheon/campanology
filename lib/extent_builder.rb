class ExtentBuilder < Extent
  
  attr_accessor :n
  
  def initialize(n)
    self.n = n
    self.rows = []
    build_extent
  end
  
  def build_extent
    if self.n > 2 then
      build_extent_recursively
    elsif self.n > 0 then
      build_trivial_extent
    end
  end
  
  def build_trivial_extent
    if self.n == 2 then
      self.rows = [ [1,2], [2,1] ]
    else
      self.rows = [ [1] ]
    end
  end
  
  def build_extent_recursively
    base_extent = ExtentBuilder.new(self.n - 1).rows
    base_extent.each { |row| grow_row(row).each { |grown| self.rows << grown } }
    
    self.rows
  end
  
  private
  
  def grow_row(row)
    indices = (0..(self.n-1)).to_a
    
    indices.reverse! if @reverse
    @reverse = !@reverse
    
    [].tap do |rows|    
      indices.each do |position|
        rows << row.clone.insert(position, self.n).flatten
      end
    end
  end
end