# 
# pool
#
# fitnessは0に近いほど適応度が高いものとする
# ただし負の値は設定しないこと
#
require 'ga/individual'
#require 'pp'
#require 'profile'

module Ga
  class Pool
    #attr_reader :pool, :generation, :deffunc, :best_indv
    def initialize(deffunc)
      raise DefineFunctionError unless deffunc.kind_of? Base
      @deffunc = deffunc
      @generation = 0
      @best_indv = nil
      @ncross, @nmutation = 0, 0
      @test_case_info = {}
      @mating_pool = []
      generate(@pool = [])
    end

    def eval_training_case(options = {})
      @best_indv = nil
      @pool.each_with_index do |indv, i|
        if indv.fitness.nil?
          indv.fitness = @deffunc.eval_training_case(indv.chrom, options)
        end
        if @best_indv.nil? || indv.fitness < @best_indv.fitness
          @best_indv = indv.dup
        end
      end
      sort_pool
      print_best_individual
    end

    def eval_test_case(options = {})
      fitness = @deffunc.eval_test_case(@best_indv.chrom, options)
      print_test_result(fitness)
      if @test_case_info[:fitness].nil? ||
          fitness < @test_case_info[:fitness]
        @test_case_info[:fitness] = fitness
        @test_case_info[:generation] = @generation
      end
    end

    def terminal_early?
      @deffunc.terminal_early?(info())
    end

    def each
      @pool.each { |indv| yield(indv) }
    end

    def each_with_index
      @pool.each_with_index { |indv, i| yield(indv, i) }
    end

    def [](n) @pool[n] end
    def size() @pool.size end
    alias population size

    def operate
      @best_indv = nil
      @nmutation = 0
      @ncross = 0
      (@pool.size / 2).times do |i|
        if flip_cross
          children = crossover
          @mating_pool << children if children
        end
      end
      @pool.each { |indv| indv.age += 1 }
      @mating_pool.flatten!
      replace()
      @pool.size.times { |i| mutate(i) }
      @generation += 1
      print_operation_result
      return [@ncross, @nmutation]
    end

    def info
      max_fitness, min_fitness, avg_fitness = 0.0, nil, 0.0
      sum_fitness = 0.0
      best_index = nil
      @pool.each_with_index do |indv, i|
        if indv.fitness
          if indv.fitness > max_fitness
            max_fitness = indv.fitness 
          end
          if min_fitness.nil? || indv.fitness < min_fitness
            min_fitness = indv.fitness 
            best_index = i
          end
          sum_fitness += indv.fitness
        end
      end
      info = {}
      info[:max_fitness] = max_fitness
      info[:min_fitness] = min_fitness
      info[:avg_fitness] = sum_fitness / @pool.size
      info[:population] = @pool.size
      info[:generation] = @generation
      info[:best_index] = best_index
      info[:ncross] = @ncross
      info[:nmutation] = @nmutation
      info[:best_validation_fitness] = @test_case_info[:fitness]
      info[:best_validation_generation] = @test_case_info[:generation]
      return info
    end

    def print_completion_message
      tci = @test_case_info
      STDOUT.print <<-END_OF_STRING
--------------------------------
Best tree found on gen #{tci[:generation]}, VALIDATION fitness = #{tci[:fitness]}
      END_OF_STRING
    end

    #######
    private
    #######
    def mutate(i)
      @nmutation += @pool[i].mutate
    end

    def crossover
      new_indv = []
      idx1, idx2 = select_parents
      parent1 = @pool[idx1]
      parent2 = @pool[idx2]
      child1 = Individual.new
      child2 = Individual.new
      parent1.crossover(parent2, child1, child2, Params[:crossover_type])
      new_indv << child1 << child2
      @ncross += 1
      return new_indv
    end

    def elite_num
      (@pool.size * (1.0 - Params[:generation_gap])).to_i
    end

    def generate(target)
      Params[:population].times do |i|
        target[i] = Individual.new do |chrom|
           @deffunc.generate(chrom)
           raise DefineFunctionError unless chrom.size > 0
           chrom.each do |gene|
             raise DefineFunctionError unless gene.kind_of? Gene
           end
         end
      end
    end

    def select_parents
      indices = []
      case Params[:select_type]
      when 'TOURNAMENT'
        ntry = 0
        until indices.size == 2
          cand = []
          dmy = Array.new(@pool.size) { |i| i }
          Params[:tournament_k].times do
            ret = rand(dmy.size)
            if dmy[ret] && @pool[dmy[ret]].adjusted_fitness
              cand << dmy[ret]
              dmy.delete_at(ret)
            end
          end
          indices << cand.sort do |e1, e2|
            @pool[e1].adjusted_fitness <=> @pool[e2].adjusted_fitness
          end.last
          ntry += 1
          raise "Couldn't find parents" if ntry > 10
        end
      when 'ROULETTE'
        until indices.size == 2
          sum = 0.0
          @pool.each { |indv| sum += indv.adjusted_fitness }
          wheel = sum * rand()
          tmp = nil
          @pool.each_with_index do |indv, i|
            if (wheel -= indv.adjusted_fitness) <= 0
              tmp = i; break
            end
          end
          tmp = @pool.size - 1 unless tmp
          indices << tmp
        end
      end
      return indices
    end

    def replace
      @mating_pool.each do |indv|
        indv.fitness = @deffunc.eval_training_case(indv.chrom, {})
      end
      @mating_pool.sort! do |a, b|
        a.adjusted_fitness <=> b.adjusted_fitness
      end
      pp = 0
      @mating_pool.each do |indv|
        if indv.adjusted_fitness > @pool[pp].adjusted_fitness
          @pool[pp] = indv
        end
        pp += 1
      end
      raise unless @pool.size == Params[:population]
      @mating_pool = []
    end

    def sort_pool
      @pool.sort! do |a, b|
        a.adjusted_fitness <=> b.adjusted_fitness
      end
    end

    def print_operation_result
      info = info()
      STDOUT.print <<-END_OF_STRING
Operation result:
  N cross = #{info[:ncross]},  N mutation = #{info[:nmutation]}
      END_OF_STRING
    end

    def print_best_individual
      STDOUT.print <<-END_OF_STRING
--------------------------------
Generation  = #{info[:generation]},   Avg fitness = #{info[:avg_fitness]}
Best indv: fitness = #{@best_indv.fitness}, age = #{@best_indv.age}, size = #{@best_indv.size}
      END_OF_STRING
      @best_indv.print_chrom
      puts
    end

    def print_test_result(best_validation)
      STDOUT.puts "Best validation fitness: #{best_validation}"
    end

    def flip_cross
      rand < Params[:crossover_fraction] ? true : false
    end
  end
end
