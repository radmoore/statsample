module Statsample
module Factor
  # Base class for rotate matrixes
  # References: 
  # * SPSS Manual
  # * Johnny Lin code for IDL: http://www.johnny-lin.com/idl_code/varimax_k58.pro
  # Use Varimax, Equimax or Quartimax for desired type of rotation
  #   Use:
  #   a = Matrix[ [ 0.4320,  0.8129,  0.3872] 
  #     , [ 0.7950, -0.5416,  0.2565]  
  #     , [ 0.5944,  0.7234, -0.3441]  
  #     , [ 0.8945, -0.3921, -0.1863] ]
  #   rotation = Statsample::Factor::Varimax(a)
  #   rotation.iterate
  #   p rotation.rotated
  #   p rotation.component_transformation_matrix
  # 
  class Rotation
    MAX_PRECISION=1e-15
    attr_reader :iterations, :rotated, :component_transformation_matrix, :h2
    def initialize(matrix, opts=Hash.new)
      @matrix=matrix
      @n=@matrix.row_size # Variables, p on original
      @m=@matrix.column_size # Factors, r on original
      @component_transformation_matrix=nil
      @h2=(@matrix.collect {|c| c**2} * Matrix.column_vector([1]*@m)).column(0).to_a
    end
    alias_method :communalities, :h2
    alias_method :rotated_component_matrix, :rotated
    # Start iteration of 
    def iterate(max_i=25)
      t=Matrix.identity(@m)
      b=@matrix.dup
      h=Matrix.diagonal(*@h2).collect {|c| Math::sqrt(c)}
      h_inverse=h.collect {|c| c!=0 ? 1/c : 0 }
      bh=h_inverse*b
      @not_converged=true
      @iterations=0
      while @not_converged
        break if iterations>max_i 
        @iterations+=1
        #puts "Iteration #{iterations}"
        num_pairs=@m*(@m-1).quo(2)
        (0..(@m-2)).each do |i| #+ go through factor index 0:r-1-1 (begin)
          ((i+1)..(@m-1)).each do |j| #+ pair i to "rest" of factors (begin)
            
            xx = bh.column(i)
            yy = bh.column(j)
            tx = t.column(i)
            ty = t.column(j)
            
            uu = @n.times.collect {|var_i| xx[var_i]**2-yy[var_i]**2}
            vv = @n.times.collect {|var_i| 2*xx[var_i]*yy[var_i]}
            
            a  = @n.times.inject(0) {|ac,var_i| ac+ uu[var_i] }
            b  = @n.times.inject(0) {|ac,var_i| ac+ vv[var_i] }
            c  = @n.times.inject(0) {|ac,var_i| ac+ (uu[var_i]**2 - vv[var_i]**2) }
            d  = @n.times.inject(0) {|ac,var_i| ac+ (2*uu[var_i]*vv[var_i]) }
            num=x(a,b,c,d)
            den=y(a,b,c,d)
            phi=Math::atan2(num,den) / 4.0
            # puts "#{i}-#{j}: #{phi}"
            
            if(Math::sin(phi.abs) >= MAX_PRECISION)
              xx_rot=( Math::cos(phi)*xx)+(Math::sin(phi)*yy)
              yy_rot=((-Math::sin(phi))*xx)+(Math::cos(phi)*yy)
              
              
              tx_rot=( Math::cos(phi)*tx)+(Math::sin(phi)*ty)
              ty_rot=((-Math::sin(phi))*tx)+(Math::cos(phi)*ty)

              
              bh=bh.to_a

              @n.times {|row_i|
                bh[row_i][i] = xx_rot[row_i]
                bh[row_i][j] = yy_rot[row_i]
              }
              t=t.to_a
              @m.times {|row_i|
                t[row_i][i]=tx_rot[row_i]
                t[row_i][j]=ty_rot[row_i]
              }
              
              bh=Matrix.rows(bh)
              t=Matrix.rows(t)
            else
              num_pairs=num_pairs-1
              @not_converged=false if num_pairs==0
            end # if
          end #j
        end #i
      end # while
      @rotated=h*bh
      @component_transformation_matrix=t
      @rotated
    end

  end
  class Varimax < Rotation
    def x(a,b,c,d)
      d-(2*a*b / @n.to_f)
    end
    def y(a,b,c,d)
      c-((a**2-b**2) / @n.to_f)
    end
  end
  class Equimax < Rotation
    def x(a,b,c,d)
      d-(@m*a*b / @n.to_f)
    end
    def y(a,b,c,d)
      c-@m*((a**2-b**2) / (2*@n.to_f))
    end
  end
  class Quartimax < Rotation
    def x(a,b,c,d)
      d
    end
    def y(a,b,c,d)
      c
    end
  end
end
end