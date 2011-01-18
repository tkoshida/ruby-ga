require 'ga/pool'

module Ga
  class GaSystem
    def initialize(deffunc)
      raise DefineFunctionError unless deffunc.kind_of? Base
      print_opening_message
      Ga.print_params
      @deffunc = deffunc
      @pool = Pool.new(@deffunc)
      @pool.eval_training_case
      @pool.eval_test_case
    end

    def start(generations)
      generations.times do |i|
        @pool.operate
        @pool.eval_training_case
        @pool.eval_test_case
        break if @pool.terminal_early?
      end
      @pool.print_completion_message
    end
    
    #######
    private
    #######
    def print_opening_message
      STDOUT.print <<-END_OF_STRING
*********************************************
*           Welcom to Ga system             *
*                           version: 0.0.1  *
*********************************************
      END_OF_STRING
    end
  end
end
