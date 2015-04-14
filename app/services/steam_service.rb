class SteamService
  attr_accessor :games, :id
  def initialize user
    @user = user
    @id = SteamId.new(user.steamid)
    @games = @id.games
  end

  def update!
    @games.each do |k, game|
      
      this_game = find_game(game)
      this_stat = find_stat(this_game)
      
      begin 
        game_stats = @id.game_stats(game.app_id.to_i)
        achievements = game_stats.achievements
      rescue
      end

      if !achievements.nil?
        achievements.each do |achievement|
          find_achievement(achievement, this_game)
        end
      end

      this_stat.update_columns(total_playtime: @id.total_playtime(this_game.app_id), recent_playtime: @id.recent_playtime(this_game.app_id))
    end
  end

  def short_update!
    update_game!
    @user.user_stats.where('recent_playtime != 0').where.not(game_id: Game.where(name: @id.most_played_games.keys).pluck(:id)).update_all(recent_playtime: 0)
    update_recent_game!
  end

  def update_game!
    (@games.keys - @user.games.pluck(:app_id)).each do |app_id|
      game = find_game(@games[app_id])
      this_stat = find_stat(game)
    end
  end

  def update_recent_game!
    @id.most_played_games.each do |k, v|
      this_game = Game.find_by(name: k)
      return if this_game.nil?

      this_stat = find_stat(this_game)

      begin
        game_stats = @id.game_stats(k)
        achievements = game_stats.achievements
      rescue
      end

      if !achievements.nil?
        achievements.each do |achievement|
          find_achievement(achievement, this_game)
        end
      end
      
      this_stat.update_columns(total_playtime: @id.total_playtime(this_game.app_id), recent_playtime: @id.recent_playtime(this_game.app_id))

    end
  end

  def find_game(game)
    this_game = Game.find_or_create_by(app_id: game.app_id, name: game.name, short_name: game.short_name)
    this_game.update_column(:store_url, game.store_url)

    if this_game.images.empty?
      Image.upload_url(game.logo_url, this_game, nil, @user)
    end
    return this_game
  end

  def find_stat(game)
    this_stat = UserStat.find_or_create_by(user_id: @user.id, game_id: game.id)
    return this_stat
  end

  def find_achievement(achievement, game)
    this_achievement = Achievement.find_or_create_by(game_id: game.id, api_name: achievement.api_name)
    name = achievement.name
    name.force_encoding(Encoding::UTF_8)
    begin
      this_achievement.update_columns(name: name, description: achievement.description, icon_open_url: achievement.icon_open_url, icon_closed_url: achievement.icon_closed_url)
    rescue
      p "random error"
    end
    if achievement.unlocked?
      this_user_achievement = UserAchievement.find_or_create_by(user_id: @user.id, achievement_id: this_achievement.id, timestamp: achievement.timestamp)
    end
    return this_user_achievement
  end

  def update_online_state!
    @user.update_column(:online, @id.online?)
  end

  def self.update_online!
#    User.public_steam_users.each do |user|
#      self.new(user).update_online_state!
#    end

    nb_online = ScanService.scan_steam_players.count
    SaveData.create(nb_users: User.count, nb_steam_users: User.steam_users.count, nb_online_users: nb_online)
  end

  def self.update_all!
    start_script = Time.now
    
    puts "Update started at : #{start_script}"
    
    User.public_steam_users.each do |user|
        steam = self.new(user)
        ActiveRecord::Base.transaction do
          user.update_column(:online, steam.id.online?)
          if user.to_scan
            steam.update!
            user.update_columns(to_scan: false)
          else
            steam.short_update!
          end
        end
    end

    Game.transaction do
      Game.all.each do |game|
        total_playtime = UserStat.where(game_id: game.id).sum('total_playtime')
        recent_playtime = UserStat.where(game_id: game.id).sum('recent_playtime')
#        in_cache = AckbarService.in_cache?(game.app_id)
        game.update_columns(total_playtime: total_playtime, recent_playtime: recent_playtime, users_count: game.users.length, user_achievements_count: game.user_achievements.length)
      end
    end
    
    SaveData.create(nb_games: Game.count, nb_played_games: Game.played.count, nb_achievements: UserAchievement.count, recent_playtime: UserStat.all.sum(:recent_playtime), total_playtime: UserStat.all.sum(:total_playtime))
    
    end_script = Time.now

    puts "Update ended at : #{end_script}"
    
    puts "Executed in #{ActionController::Base.helpers.distance_of_time_in_words(start_script, end_script)}"
  end

end
