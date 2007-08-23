class Example
  module Dispatch
    BASE_DIR = File.join(File.dirname(__FILE__), '..', '..')

    example_alist = [
      %w[ value Value ],
      %w[ cond Cond ],
      %w[ foreach Foreach ],
      %w[ link Link ],
      %w[ action Action ],
      %w[ import Import ],
      %w[ submit Submit ],
      %w[ text Text ],
      %w[ password Password ],
      %w[ checkbox Checkbox ],
      %w[ radio Radio ],
      %w[ select Select ],
      %w[ textarea Textarea ]
    ]

    EXAMPLE_KEYS = example_alist.map{|k, n| k }
    EXAMPLES = {}
    for key, name in example_alist
      EXAMPLES[key] = {
	:class => Example.const_get(name),
	:code => File.join(BASE_DIR, 'lib', 'Example', "#{name}.rb"),
	:view => File.join(BASE_DIR, 'view', 'Example', "#{name}.rhtml")
      }
    end

    attr_accessor :c

    def page_start
      @key = @c.req['example'] or raise "not found a query parameter: example"
      ex = EXAMPLES[@key] or raise "not found a example: #{@key}"
      @class = ex[:class]
      @code = ex[:code]
      @view = ex[:view]
    end

    attr_reader :key
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
