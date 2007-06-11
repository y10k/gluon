class Example
  module Dispatch
    BASE_DIR = File.join(File.dirname(__FILE__), '..', '..')

    EXAMPLES = {}
    [ %w[ value Value ],
      %w[ cond Cond ],
      %w[ foreach Foreach ],
      %w[ link Link ],
      %w[ import Import ]
    ].each do |key, name|
      EXAMPLES[key] = {
	:class => Example.const_get(name),
	:code => File.join(BASE_DIR, 'lib', 'Example', "#{name}.rb"),
	:view => File.join(BASE_DIR, 'view', 'Example', "#{name}.rhtml")
      }
    end

    attr_accessor :req

    def page_start
      @key = @req['example'] or raise "not found a query parameter: example"
      ex = EXAMPLES[@key] or raise "not found a example: #{@key}"
      @class = ex[:class]
      @code = ex[:code]
      @view = ex[:view]
    end

    def example
      "/example/ex_panel?example=#{@key}"
    end

    def code
      "/example/code_panel?example=#{@key}"
    end

    def view
      "/example/view_panel?example=#{@key}"
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
