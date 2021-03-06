# == Schema Information
#
# Table name: games
#
#  id                      :integer          not null, primary key
#  name                    :string(255)
#  app_id                  :integer
#  short_name              :string(255)
#  recent_playtime         :integer          default(0)
#  total_playtime          :integer          default(0)
#  created_at              :datetime
#  updated_at              :datetime
#  store_url               :string(255)
#  in_cache                :boolean          default(FALSE)
#  user_achievements_count :integer          default(0)
#  users_count             :integer          default(0)
#  comments_count          :integer          default(0)
#  has_port_forwarding     :boolean          default(FALSE)
#  slug                    :string(255)
#  achievements_count      :integer          default(0)
#

class GamesController < ApplicationController
  before_action :set_game, only: [:show, :achievements, :ask_permission, :follow]

  before_action do
    add_breadcrumb_if_can t('activerecord.models.game', count: 2), games_path, :index, Game
  end
  before_action only: [:show, :achievements] do
    add_breadcrumb_if_can @game.name, game_path(@game), :show, @game
  end

  def index
    session[:games] = params[:games] if params[:games]
    session[:q] = params[:q] if params[:q]

    if params[:achievement_duration] && params[:achievement_duration] =~ /^\d+$/
      @duration = params[:achievement_duration].to_i
    else
      @duration = 15
    end

    @step = if params[:achievement_step] && params[:achievement_step] =~ /^\d+$/
              params[:achievement_step].to_i
            else
              1
            end

    @user_achievements = UserAchievement.unscoped.order(timestamp: :desc).limit(6).includes(user: :images, achievement: :game)

    if !session[:q].blank?
      @games = Game.where('name LIKE ?', "%#{session[:q]}%").includes(:images).page(params[:page]).sortable(params[:sort_field], params[:sort_order])
    elsif session[:games] == 'all'
      @games = Game.includes(:images).all.page(params[:page]).sortable(params[:sort_field], params[:sort_order])
    else
      @games = Game.includes(:images).order(total_playtime: :desc).page(params[:page]).sortable(params[:sort_field], params[:sort_order])
    end
    @last_games = Game.where('recent_playtime > 0').order('rand()').includes(:images).limit(5)
  end

  def show
    @lan_parties = if can? :see, LanParty
                     @game.lan_parties.visible_on_lan
                   else
                     @game.lan_parties.visible_on_landing
                   end

    current_user.box.read_notification(@game) if current_user
  end

  def achievements
    add_breadcrumb t('activerecord.models.achievement', count: 2)
  end

  def ask_permission
    authorize! :ask_permission, @game

    if Mailer.ask_permission_email(@game.id, current_user.id).deliver
      flash[:notice] = t('steam.firewall.success')
    else
      flash[:error] = t('steam.firewall.error')
    end
    respond_to do |format|
      format.html { redirect_to @game }
    end
  end

  def reload_achievements
    if params[:datemin] && params[:datemax]
      @datemin = Time.strptime(params[:datemin], '%Y-%m-%d %H:%M:%S')
      @datemax = Time.strptime(params[:datemax], '%Y-%m-%d %H:%M:%S')
      if !User.where(id: params[:user_id]).empty?
        @user_achievements = UserAchievement.unscoped.where(timestamp: @datemin..@datemax, user_id: params[:user_id]).order(timestamp: :desc).limit(6).includes(user: :images, achievement: :game)
      elsif !Game.where(id: params[:game_id]).empty?
        @user_achievements = UserAchievement.unscoped.joins(:game).where(timestamp: @datemin..@datemax, 'games.id' => params[:game_id]).order(timestamp: :desc).limit(6).includes(user: :images, achievement: :game)
      else
        @user_achievements = UserAchievement.unscoped.where(timestamp: @datemin..@datemax).order(timestamp: :desc).limit(6).includes(user: :images, achievement: :game)
      end
    else
      @datemin = nil
      @datemax = nil
      if !User.where(id: params[:user_id]).empty?
        @user_achievements = UserAchievement.unscoped.where(user_id: params[:user_id]).order(timestamp: :desc).limit(6).includes(user: :images, achievement: :game)
      elsif !Game.where(id: params[:game_id]).empty?
        @user_achievements = UserAchievement.unscoped.joins(:game).where('games.id' => params[:game_id]).order(timestamp: :desc).limit(6).includes(user: :images, achievement: :game)
      else
        @user_achievements = UserAchievement.unscoped.order(timestamp: :desc).limit(6).includes(user: :images, achievement: :game)
      end
    end
    respond_to do |format|
      format.js
    end
  end

  def follow
    authorize! :follow, @game
    @game.followers << current_user

    respond_to do |format|
      format.html { redirect_to @game }
      format.js
    end
  end

  private

  def set_game
    @game = Game.find_by(slug: params[:id])
    render 'shared/not_found', status: 404 unless @game
  end
end
