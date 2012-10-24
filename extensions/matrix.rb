class Matrix
  
  def self.drop(matrix, indices)
    # raise ArgumentError unless matrix.symmetric?
    
    n = matrix.row_size - indices.length
    
    post = Matrix.identity(n).column_vectors.map(&:to_a)
    indices.each { |i| post.insert(i, [0]*n) }
    post = Matrix[*post]
    pre = post.transpose
    
    pre * matrix * post
  end
  
  def set(i, j, x)
    @rows[i][j] = x
  end
  
end