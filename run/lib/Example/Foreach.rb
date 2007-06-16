class Example
  class Foreach
    class User
      def initialize(name, age)
        @name = name
        @age = age
      end

      attr_reader :name
      attr_reader :age
    end

    def initialize
      @fruits = %w[ apple banana orange ]
      @users = [
        User.new('Taro', 21),
        User.new('Hanako', 23),
        User.new('Tanaka', 18)
      ]
      @country = 'Japanese'
    end

    attr_reader :fruits
    attr_reader :users
    attr_reader :country
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
