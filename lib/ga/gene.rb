module Ga
  class Gene
    OVERWRITE_MESSAGE = "You should overwrite this method."

    def initialize
      raise NotImplementedError, OVERWRITE_MESSAGE
    end

    def mutate
      raise NotImplementedError, OVERWRITE_MESSAGE
    end

    def print_stat
      # Overwrite this method
      print "?"
    end
  end
end
