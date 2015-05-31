# == Schema Information
#
# Table name: lan_games
#
#  id           :integer          not null, primary key
#  name         :string(255)
#  game_scanner :string(255)
#  game_id      :integer
#  created_at   :datetime
#  updated_at   :datetime
#

class LanGame < ActiveRecord::Base
  belongs_to :lan_party
  belongs_to :game
  has_many :lan_game_relations

  def images
    Image.where(imageable_id: self.lan_game_relations.pluck(:id), imageable_Type: LanGameRelation)
  end

end