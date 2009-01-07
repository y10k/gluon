class Example
  module DispatchController
    include Gluon::Controller
    include Gluon::ERBView

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
      %w[ textarea Textarea ],
      %w[ session Session ],
      [ 'pagecache', 'PageCache', 'page cache' ],
      [ 'onetimetoken', 'OneTimeToken', 'one time token' ],
      [ 'errmsgs', 'ErrorMessages', 'error messages' ],
      %w[ table Table ]
    ]

    EXAMPLES = {}
    EXAMPLE_KEYS = example_alist.map{|k, n| k }
    EXAMPLE_KEY_MAP = {}

    for key, name, title in example_alist
      example_type = Example.const_get(name)
      EXAMPLES[key] = {
	:class => example_type,
	:code => File.join(BASE_DIR, 'lib', 'Example', "#{name}.rb"),
	:view => File.join(BASE_DIR, 'view', 'Example', "#{name}#{Gluon::ERBView::SUFFIX}"),
        :title => title || key
      }
      EXAMPLE_KEY_MAP[example_type] = key
    end

    regexp_example_keys =
      EXAMPLE_KEYS.map{|k| Regexp.quote(k) }.join('|')

    gluon_path_filter %r"^/(#{regexp_example_keys})$" do |example|
      key = EXAMPLE_KEY_MAP[example] or
        raise "not a example page type `#{example}'"
      "/#{key}"
    end

    def page_start(key)
      @key = key
      ex = EXAMPLES[@key] or raise "not found a example: #{key.inspect}"
      @header = Header.new(ex[:class])
      @class = ex[:class]
      @code = ex[:code]
      @view = ex[:view]
      @title = ex[:title]
    end

    def page_get
    end

    attr_reader :header
    attr_reader :key
    attr_reader :title
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
