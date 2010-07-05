# -*- coding: utf-8 -*-

module Gluon
  module Web
    module SessionAddOn
      Config = Struct.new(:max_age)

      def self.create_config
	Config.new(60 * 5)
      end

      def __addon_init__
	super			# for add-on chain.

	@r.logger.debug("#{self}: __addon_init__ at #{SessionAddOn}.") if @r.logger.debug?
	if (@r.equest.session.key? :gluon_session) then
	  mtime, session = @r.equest.session[:gluon_session]
	  if (Time.now - mtime > @r.config(SessionAddOn).max_age) then
	    @r.logger.debug("#{self}: #{SessionAddOn}: expired session: #{mtime}") if @r.logger.debug?
	    @r.equest.session.delete(:gluon_session)
	  else
	    @r.logger.debug("#{self}: #{SessionAddOn}: load session: #{mtime}") if @r.logger.debug?
	    @session = session
	  end
	end
      end

      def create_session(overwrite=false)
        if (overwrite) then
          @session = {}
        else
          @session ||= {}
        end
      end

      def delete_session
	@session = nil
      end

      def __addon_final__
	@r.logger.debug("#{self}: __addon_final__ at #{SessionAddOn}.") if @r.logger.debug?
	if (@session) then
	  mtime = Time.now
	  @r.logger.debug("#{self}: #{SessionAddOn}: save session: #{mtime}.") if @r.logger.debug?
	  @r.equest.session[:gluon_session] = [ mtime, @session ]
	else
	  if (@r.equest.session.key? :gluon_session) then
	    @r.logger.debug("#{self}: #{SessionAddOn}: delete session.") if @r.logger.debug?
	    @r.equest.session.delete(:gluon_session)
	  end
	end

	super
      end
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
