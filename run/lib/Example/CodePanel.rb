class Example
  class CodePanel
    include Dispatch

    attr_reader :key

    def code_page
      IO.read(@code)
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
