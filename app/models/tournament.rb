class Tournament < ActiveRecord::Base
  belongs_to :lan_game
  has_many :tournament_users
  has_many :users, through: :tournament_users, dependent: :destroy

  delegate :name, to: :lan_game, prefix: true, allow_nil: true
  delegate :name, to: :lan, prefix: true, allow_nil: true
end
