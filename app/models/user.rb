# == Schema Information
#
# Table name: users
#
#  id                     :integer          not null, primary key
#  name                   :string(255)
#  created_at             :datetime
#  updated_at             :datetime
#  email                  :string(255)      default(""), not null
#  encrypted_password     :string(255)      default(""), not null
#  reset_password_token   :string(255)
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  sign_in_count          :integer          default(0), not null
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :string(255)
#  last_sign_in_ip        :string(255)
#  confirmation_token     :string(255)
#  confirmed_at           :datetime
#  confirmation_sent_at   :datetime
#  steamid                :integer
#  steam_name             :string(255)
#  steam_url              :string(255)
#  steam_public           :boolean          default(FALSE)
#  online                 :boolean          default(FALSE)
#  to_scan                :boolean          default(TRUE)
#  sha_password           :string(255)
#  pseudo                 :string(255)
#  stepmania_id           :integer
#  stepmania_xp           :integer
#  sha1_password          :string(255)
#  secret                 :string(255)
#  slug                   :string(255)
#

class User < ActiveRecord::Base
  include Sortable
  sortable_fields :all

  attr_accessor :temp_password
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :confirmable

  has_many :played_game, -> { where('user_stats.total_playtime > ?', 0) }, through: :user_stats, source: 'game'
  has_many :user_achievements, dependent: :destroy
  has_many :achievements, through: :user_achievements
  has_many :recent_plays, -> { joins(:user_stats).where('user_stats.recent_playtime > ?', 0) }, through: :user_stats, source: 'game'
  has_many :favorite_games, -> { joins(:user_stats).order('user_stats.total_playtime DESC').limit(10) }, through: :user_stats, source: 'game'
  has_many :games, through: :user_stats, after_add: :follow_this_game
  has_many :user_stats, dependent: :destroy
  has_many :borrowings
  has_many :supplies
  has_many :sections
  has_many :packs
  has_many :pages
  has_many :images, class_name: 'Image', as: 'imageable', dependent: :destroy
  has_and_belongs_to_many :groups, join_table: 'users_groups'
  has_one :mail_box
  has_many :streams
  has_one :active_stream, -> { where('end_at IS NULL').order('streams.created_at DESC').limit(1) }, class_name: 'Stream'
  has_many :active_streams, -> { where('end_at IS NULL') }, class_name: 'Stream'
  has_many :resource_followers
  has_many :user_responses
  has_many :comments
  has_many :response_surveys, through: :user_responses
  has_many :surveys, through: :response_surveys
  has_many :open_smo_stats
  has_many :stepmania_songs, through: :open_smo_stats
  has_many :stepmania_packs, through: :stepmania_songs
  has_many :save_datas

  scope :steam_users, -> { where('steamid IS NOT NULL') }
  scope :public_steam_users, -> { where('steamid IS NOT NULL AND steam_public = ?', true) }
  scope :online, -> { where(online: true) }
  scope :stepmania_users, -> { where('stepmania_xp > 0') }

  before_save :set_name_and_pseudo!
  before_save :generate_sha_password
  before_save :set_slug
  after_create :regenerate_secret!

  def ability
    @ability ||= Ability.new(self)
  end
  delegate :can?, :cannot?, to: :ability

  def achievements_in(game)
    achievements.where(game: game)
  end

  def has_achievements?(game)
    !achievements_in(game).empty?
  end

  def has_achievement?(achievement)
    !achievements.where(id: achievement.id).empty?
  end

  def is_admin?
    test = false
    groups.each do |group|
      test |= group.admin
    end
    test
  end

  def is_in?(cat)
    return true if is_admin?
    test = false
    groups.each do |group|
      test |= group[cat]
    end
    test
  end

  def is_a_steam_user?
    !steamid.nil?
  end

  def is_a_public_steam_user?
    steam_public
  end

  def level
    test = 0
    groups.each do |group|
      test = group.level if group.level > test
    end
    test
  end

  def fullname
    !pseudo.blank? ? "#{name} (#{pseudo})" : name
  end

  def active_basket
    active_basket = borrowings.where(effective: false).last
    if active_basket
      active_basket
    else
      new_basket
    end
  end

  def supply_in_basket
    active_basket.supplies
  end

  def nb_supplies_in_basket(supply)
    request = active_basket.supply_requests.find_by(supply: supply)
    if request
      request.nb_supplies
    else
      0
    end
  end

  def new_basket
    Borrowing.create(user: self)
  end

  def box
    mail_box.nil? ? new_box : mail_box
  end

  def new_box
    MailBox.create(user: self)
  end

  def save_basket!
    active_basket.update_columns(effective: true)
  end

  def confirmed?
    confirmed_at.nil? ? false : true
  end

  def confirm!
    update_column(:confirmed_at, Time.now)
  end

  def avatar(size = 'mini')
    if !images.empty?
      case size
      when 'mini'
        images.last.mini_url
      when 'thumb'
        images.last.thumb_url
      when 'medium'
        images.last.medium_url
      else
        images.last.url
      end
    else
      '/assets/avatar.jpg'
    end
  end

  def total_playtime
    user_stats.sum(:total_playtime)
  end

  def recent_playtime
    user_stats.sum(:recent_playtime)
  end

  def stepmania_playtime
    open_smo_stats.joins(:open_smo_song).pluck('open_smo_songs.time').sum
  end

  def self.nolife
    joins(:user_stats).group('users.id').order('SUM(user_stats.recent_playtime) ASC').last
  end

  def self.polard
    joins(:user_stats).group('users.id').order('SUM(user_stats.recent_playtime) ASC, SUM(user_stats.total_playtime) ASC').first
  end

  def regenerate_secret!
    update_columns(secret: SecureRandom.hex(8))
  end

  def to_param
    slug
  end

  private

  def set_name_and_pseudo!
    email =~ /(.+)\.(.+)@.+/
    firstname = Regexp.last_match(1)
    lastname = Regexp.last_match(2)
    if name.blank?
      if firstname && lastname
        self.name = firstname.capitalize + ' ' + lastname.capitalize
      else
        resource.email =~ /(.+)@.+/
        self.name = Regexp.last_match(1).capitalize
      end
    end

    self.pseudo = name.parameterize('_') if pseudo.blank?
    self.pseudo += '_' until User.where('pseudo LIKE ? AND id != ?', self.pseudo, self.id).empty?
  end

  def set_slug
    self.pseudo = nil if pseudo.blank?
    self.slug = pseudo ? pseudo.parameterize : id
  end

  def follow_this_game(game)
    game.followers << self
  end

  def generate_sha_password
    unless temp_password.nil?
      sha = Digest::MD5.new
      sha.update(temp_password)
      self.sha_password = sha.hexdigest.upcase
      self.sha1_password = ('{SHA}' + Base64.encode64(Digest::SHA1.digest(temp_password))).delete("\n")
    end
  end
end
