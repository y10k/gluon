# -*- coding: utf-8 -*-

class Example
  class OneTimeToken < Gluon::Controller
    include Gluon::Validation
    include Gluon::Web::ErrorMessages::AddOn
    include Gluon::Web::Form::AddOn('post', 'target' => 'main')
    include Gluon::Web::OneTimeToken::AddOn
    include Gluon::Web::SessionAddOn

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
      create_session
      @header_footer = HeaderFooter.new(@r, self.class)
      @session[:count] = 0 unless (@session.key? :count)
      @now = Time.now
    end

    def request_POST
      validation(@errors) do |v|
        v.one_time_token
      end
    end

    gluon_import_reader :header_footer

    def count
      @session[:count]
    end
    gluon_value :count

    def now
      @now.to_s
    end
    gluon_value :now

    def count_up
      @session[:count] += 1
    end
    gluon_submit :count_up, :value => 'Count Up'

    def count_reset
      @session[:count] = 0
    end
    gluon_submit :count_reset, :value => 'Reset'
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
