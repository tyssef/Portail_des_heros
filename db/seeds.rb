require 'faker'

# EFFACER LES DONNEES EXISTANTES
User.destroy_all
Universe.destroy_all
Character.destroy_all
Party.destroy_all
PartyCharacter.destroy_all
Message.destroy_all
Note.destroy_all

puts "les tables sont maintenant vides"

# Create 10 users
10.times do |i|
  User.create!(
    first_name: Faker::Name.first_name,
    last_name: Faker::Name.last_name,
    email: "jdr#{i+1}@jdr.com",
    password: 'password123',
    pseudo: Faker::Internet.username,
    player_level: %w[Debutant Initié Expert].sample,
    game_master: [true, false].sample,
    admin: false,
    completion_rate_basics: rand(0..100),
    completion_rate_universes: rand(0..100),
    completion_rate_characters: rand(0..100)
  )
end

puts "10 users : OK"


# Tous les débutants sont forcémcent Débutant.
User.where(player_level: 'Debutant').update_all(game_master: false)

# CREATION D'UN ADMIN
admin = User.create!(
  first_name: 'Martin',
  last_name: 'Pomme',
  email: 'admin@jdr.com',
  password: 'password123',
  pseudo: 'Admin',
  player_level: 'Expert',
  game_master: true,
  admin: true,
  completion_rate_basics: 100,
  completion_rate_universes: 100,
  completion_rate_characters: 100
)

puts "User Admin : OK"


# CREATION DE 3 UNIVERS
universes = [
  { name: 'D&D', description: 'Un monde dangereux avec des dragons' },
  { name: 'Call of Cthulhu', description: 'Un univers d’horreur cosmique' },
  { name: 'Shadowrun', description: 'Un univers cyberpunk' }
]

universes.each do |universe|
  Universe.create!(universe)
end

puts "Univers OK"

# CRÉATION DE 3 CHARACTERS PAR USER
User.all.each do |user|
    3.times do |i|
      Character.create!(
        name: Faker::Games::DnD.character,
        user: user,
        universe: Universe.all.sample,
        strength: rand(10..18).to_s,
        dexterity: rand(10..18).to_s,
        intelligence: rand(10..18).to_s,
        constitution: rand(10..18).to_s,
        wisdom: rand(10..18).to_s,
        charisma: rand(10..18).to_s,
        available_status: i < 2 ? 'Active' : 'Inactive'
      )
    end
  end

puts "3 Characters par User : OK"

# CREATION DE 6 PARTIES
6.times do
  Party.create!(
    name: Faker::Games::Tolkien.character,
    universe: Universe.all.sample,
    user: User.where(game_master: true).sample
  )
end

# NOUS AJOUTONS DES CHARACTERS AUX PARTIES
Character.all.each do |character|
  party = Party.all.sample
  PartyCharacter.create!(
    character: character,
    party: party,
    status: 'accepted'
  )

# MARQUER LES AUTRES PARTIES COMME REFUSÉE PAR LE JOUEUR
  Party.where.not(id: party.id).each do |other_party|
    PartyCharacter.create!(
      character: character,
      party: other_party,
      status: 'refused_by_player'
    )
  end
end

puts "Characters to parties : OK"

# Create notes for each character
Character.all.each do |character|
  2.times do
    Note.create!(
      user_notes: Faker::Games::WorldOfWarcraft.quote,
      other_notes: Faker::Games::Overwatch.quote,
      character: character
    )
  end
end

puts "Notes : OK"
puts "Seeding terminée!"
