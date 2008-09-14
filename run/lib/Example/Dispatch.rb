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
      %w[ textarea Textarea ],
      %w[ session Session ],
      [ 'pagecache', 'PageCache', 'page cache' ],
      [ 'onetimetoken', 'OneTimeToken', 'one time token' ],
      [ 'errmsgs', 'ErrorMessages', 'error messages' ],
      %w[ table Table ]
    ]

    EXAMPLE_KEYS = example_alist.map{|k, n| k }
    EXAMPLE_FILTER =
      Regexp.compile('^/(' +
                     EXAMPLE_KEYS.map{|k| Regexp.quote(k) }.join('|') +
                     ')$')
    EXAMPLES = {}
    for key, name, title in example_alist
      EXAMPLES[key] = {
	:class => Example.const_get(name),
	:code => File.join(BASE_DIR, 'lib', 'Example', "#{name}.rb"),
	:view => File.join(BASE_DIR, 'view', 'Example', "#{name}.rhtml"),
        :title => title || key
      }
    end

    def page_get(key)
      @key = key
      ex = EXAMPLES[@key] or raise "not found a example: #{key.inspect}"
      @class = ex[:class]
      @code = ex[:code]
      @view = ex[:view]
      @title = ex[:title]
    end

    attr_reader :key
    attr_reader :title
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
