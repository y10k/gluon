class Example
  class CodePanel
    include DispatchController

    def filename
      File.basename(@code)
    end

    def code
      IO.read(@code)
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
