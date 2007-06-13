class Example
  class CodePanel
    include Dispatch

    attr_reader :key

    def code
      IO.read(@code)
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
