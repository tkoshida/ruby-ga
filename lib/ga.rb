# Params
# * population: 集団内の個体の数(2~)
# * generation_gap: 世代間のギャップ(0.0~1.0)
# * select_type: 選択方式(TOURNAMENT, ROULETTE)
# * tournament_k: トーナメント抽出個体数(2~)
# * crossover_fraction: 交叉確率(0.0~1.0)
# * mutant_fraction: 突然変異確率(0.0~1.0)
# * crossover_type: 交叉方法(ONEPOINT/TWOPOINTS/UNIFORM)
require 'ga/gasystem'
require 'ga/pool'
require 'ga/individual'
require 'ga/base'
require 'ga/gene'

module Ga
  class ParameterError < StandardError; end
  class DefineFunctionError < StandardError; end

  Params = {}
  Params[:population] = 20
  Params[:generation_gap] = 0.9
  Params[:tournament_k] = 6
  Params[:select_type] = 'TOURNAMENT'
  Params[:crossover_fraction] = 0.8
  Params[:mutant_fraction] = 0.1
  Params[:crossover_type] = 'ONEPOINT'

  class << self
    def set_params(p)
      raise ArgumentError unless p
      p.each do |k, v|
        raise ParameterError, "Unknown key: #{k}" unless Params.has_key?(k)
      end
      Params.each do |k, v|
        next if p[k].nil?
        case k
        when :population, :tournament_k
          raise ParameterError unless p[k].to_i > 1
          Params[k] = p[k].to_i
        when :crossover_fraction, :mutant_fraction, :generation_gap
          raise ParameterError unless p[k].to_f.between?(0, 1.0)
          Params[k] = p[k].to_f
        when :select_type
          unless p[k] == 'TOURNAMENT' || p[k] == 'ROULETTE'
            raise ParameterError
          end
          Params[k] = p[k]
        when :crossover_type
          case p[k]
          when 'ONEPOINT'
          when 'TWOPOINTS'
          when 'UNIFORM'
            # ok
          else
            raise ParameterError
          end
          Params[k] = p[k]
        else
          Params[k] = p[k]
        end
      end
    end

    def print_params
      STDOUT.puts "--------- Ga::Params -----------"
      Params.each { |k, v| puts "#{k}: #{v}" }
    end
  end
end
