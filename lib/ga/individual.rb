module Ga
  class Individual
    attr_accessor :age, :chrom
    attr_reader :fitness, :adjusted_fitness
   
    def initialize
      @age = 0
      @result, @fitness, @adjusted_fitness = 0, nil, nil
      @chrom = []
      yield(@chrom) if block_given?
    end

    def fitness=(val)
      @fitness = val
      @adjusted_fitness = 1.0 / (1.0 + @fitness)
      @adjusted_fitness = 0.0 if @adjusted_fitness.infinite? ||
                                  @adjusted_fitness.nan?
    end

    def crossover(other, child1, child2, type)
      child1.chrom = []
      child2.chrom = []
      last_point = 0
      flip = 0
      cross_points = get_crosspoint(type)
      cross_points.sort!
      cross_points << @chrom.size
      cross_points.each do |cp|
        arr1, arr2 = [], []
        @chrom[last_point..cp-1].each { |g| arr1 << g.dup }
        other.chrom[last_point..cp-1].each { |g| arr2 << g.dup }
        if flip % 2 == 0
          child1.chrom << arr1
          child2.chrom << arr2
          flip = 1
        else
          child1.chrom << arr2
          child2.chrom << arr1
          flip = 0
        end
        last_point = cp
      end
      child1.chrom.flatten!
      child2.chrom.flatten!
    end

    def mutate
      nmutation = 0
      @chrom.each do |gene|
        if flip_mutate
          gene.mutate
          init_stat
          nmutation += 1
        end
      end
      return nmutation
    end

    def status
      stat = {}
      stat[:fitness] = @fitness
      stat[:adjusted_fitness] = @adjusted_fitness
      stat[:result] = @result
      stat[:age] = @age
      stat[:size] = @chrom.size
      return stat
    end

    def size() @chrom.size end

    def print_chrom
      @chrom.each_with_index do |gene, i|
        gene.print_stat
        print "," unless i == @chrom.size - 1
      end
    end

    #######
    private
    #######
    # 交叉点を取得
    def get_crosspoint(type)
      cross_points = []
      case type
      when 'ONEPOINT'
        raise StandardError, 
          "Too short chrom specified, minimum 2" unless @chrom.size > 1
        cross_points << rand(@chrom.size - 1) + 1
      when 'TWOPOINTS'
        raise StandardError, 
          "Too short chrom specified, minimum 3" unless @chrom.size > 2
        until cross_points.size == 2 do
          cp = rand(@chrom.size - 1) + 1
          unless @chrom.include?(cp)
            cross_points << cp
          end
        end
      when 'UNIFORM'
        raise StandardError, 
          "Too short chrom specified, minimum 2" unless @chrom.size > 1
        @chrom.size.times do |cp|
          cross_points << cp unless cp == 0
        end
      end
      return cross_points
    end

    def init_stat
      @result, @fitness, @adjusted_fitness = 0, nil, nil
    end

    def flip_mutate
      rand < Params[:mutant_fraction] ? true : false
    end
  end
end
