# -*- coding: utf-8 -*-

class Example
  class OneTimeToken < Gluon::Controller
    include Gluon::Validation

    def_page_encoding __ENCODING__

    # for Example::Menu and Example::Panel
    def self.description
      'one time token'
    end

    def title
      self.class.description
    end
    gluon_value :title

    def page_start
      @header_footer = HeaderFooter.new(@r, self.class)
      @errors = Gluon::Web::ErrorMessages.new
      @one_time_token = Gluon::Web::OneTimeToken.new(@r)
      @count = @r.equest.session[:count] || 0
      @now = Time.now
    end

    def request_POST
      validation(@errors) do |v|
        v.one_time_token
      end
    end

    def page_end
      @one_time_token.next_token
    end

    gluon_import_reader :header_footer
    gluon_import_reader :errors
    gluon_import_reader :one_time_token
    gluon_value_reader :count

    def now
      @now.to_s
    end
    gluon_value :now

    def count_up
      @count += 1
      @r.equest.session[:count] = @count
    end
    gluon_submit :count_up, :value => 'Count Up'

    def count_reset
      @count = 0
      @r.equest.session.delete(:count)
    end
    gluon_submit :count_reset, :value => 'Reset'
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
