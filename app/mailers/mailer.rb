class Mailer < ActionMailer::Base
  ADMIN_MAIL = 'GiGN Bureau <gign_bureau@larez.fr>'.freeze
  ALERTE_MAIL = 'GiGN Alert <gign.serveurs@larez.fr>'.freeze
  FIREWALL_MAIL = 'firewall <firewall@larez.fr'.freeze

  default from: 'GiGN <gign-noreply@larez.fr>', reply_to: ADMIN_MAIL

  def new_valid_basket_email(user_id, borrowing_id)
    @user = User.find(user_id)
    @borrowing = Borrowing.find(borrowing_id)

    mail(to: ADMIN_MAIL, subject: t('mailer.new_valid_basket_email.subject'))
  end

  def basket_accepted_email(user_id, borrowing_id)
    @user = User.find(user_id)
    @borrowing = Borrowing.find(borrowing_id)
    mail(to: @user.email, subject: t('mailer.basket_accepted_email.subject'))
  end

  def ask_permission_email(game_id, user_id)
    @user = User.find(user_id)
    @game = Game.find(game_id)
    mail(to: FIREWALL_MAIL, from: @user.email, cc: ADMIN_MAIL, bcc: @user.email, subject: t('mailer.ask_permission_email.subject', game_name: @game.name))
  end

  def mail_contact(email, message, name, ip)
    @email = email
    @name = name
    @message = message
    @ip = ip
    mail(to: ADMIN_MAIL, subject: t('mailer.mail_contact.subject', user_name: @name))
  end

  def new_blog_article(email_send_id)
    @email = EmailSend.find(email_send_id)
    mail(to: @email.receiver, subject: @email.name)
  end

  def monitoring_ping(server_id, up)
    @server = DedicatedServer.find(server_id)
    @up = up
    mail(to: ALERTE_MAIL, subject: t('mailer.monitoring_ping.subject.' + (@up ? 'up' : 'down'), server: @server.name))
  end
end
