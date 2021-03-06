class BaseController < ApplicationController
  def index
    @lan = Lan.where('start_at > ?', Time.now).last

    @last_games = Game.where('recent_playtime > 0').order('rand()').includes(:images, :port_forwarding).limit(5)
    @section = Section.blog
    @page = @section.pages.first
    @streams = Stream.active

    if can? :see, LanParty
      @lan_parties = LanParty.visible_on_lan.order(game_scanner: :asc)
    else
      @lan_parties = LanParty.visible_on_landing.order(game_scanner: :asc)
    end
  end

  def contact
    add_breadcrumb t('footer.contact')
  end

  def mail_contact
    if !params[:contact][:email].blank? && !params[:contact][:message].blank? && !params[:contact][:name].blank?
      Mailer.mail_contact(params[:contact][:email], params[:contact][:message], params[:contact][:name], request.remote_ip).deliver
      flash[:notice] = t('contact.form.success')
    else
      flash[:error] = t('contact.form.error')
    end

    respond_to do |format|
      format.html { redirect_to contact_path }
      format.js
    end
  end
end
