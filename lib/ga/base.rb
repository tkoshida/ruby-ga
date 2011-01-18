module Ga
  class Base
    OVERWRITE_MESSAGE = "You should overwrite this method."

    def initialize
    end

    # Set genes
    def generate(chrom)
      raise NotImplementedError, OVERWRITE_MESSAGE
    end

    # Return fitness
    def eval_training_case(indv, options)
      raise NotImplementedError, OVERWRITE_MESSAGE
    end

    # Return fitness
    def eval_test_case(indv, options)
      raise NotImplementedError, OVERWRITE_MESSAGE
    end

    def terminal_early?(info)
      return false
    end
  end
end
