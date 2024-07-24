class GenerateBackstoryJob < ApplicationJob
  include Rails.application.routes.url_helpers

  queue_as :default

  def perform(character_id)
    character = Character.find(character_id)
    prompt_template = YAML.load_file(Rails.root.join('config/prompts.yml'))['generate_backstory']['template']
    prompt = prompt_template % {
      name: character.name,
      race: character.race.name,
      univers_class: character.univers_class.name,
      universe: character.universe.name,
      strength: character.strength,
      dexterity: character.dexterity,
      intelligence: character.intelligence,
      constitution: character.constitution,
      wisdom: character.wisdom,
      charisma: character.charisma
    }

    client = OpenAI::Client.new
    response = nil

    begin
      response = client.chat(
        parameters: {
          model: "gpt-4o-mini",
          messages: [{ role: "user", content: prompt }],
          temperature: 0.7,
          max_tokens: 4096, # Ajustez ce nombre selon vos besoins, mais assurez-vous qu'il est inférieur à 4096.
        }
      )
    rescue Faraday::TooManyRequestsError => e
      puts "Rate limit exceeded. Retrying after delay..."
      sleep(10) # Attendez 10 secondes avant de réessayer
      retry
    end

    backstory_content = response.dig("choices", 0, "message", "content")
    character.update(backstory: backstory_content) if backstory_content.present?

    generate_image(character) if backstory_content.present?

    # Log message to console
    puts "Image generated for character: #{character.name}" if backstory_content.present?

    # Diffuser un message via Action Cable
    CharacterChannel.broadcast_to(
      character.user,
      {
        message: "Votre personnage #{character.name} est prêt",
        character_id: character.id,
        backstory: character.backstory,
        photo_url: url_for(character.photo)
      }
    )
  end

  private

  def generate_image(character)
    prompt = <<~PROMPT
      Créez un portrait épique en pied d'un personnage nommé #{character.name} de l'univers de #{character.universe.name}. 
      Ce personnage appartient à la race #{character.race.name} et a la classe #{character.univers_class.name}. 
      Le personnage doit être dans une pose dynamique et héroïque, mettant en valeur ses attributs et son équipement uniques. 
      L'arrière-plan doit être entièrement blanc pour mettre en évidence les détails et le design du personnage. 
      Le style doit être très détaillé et vibrant, capturant l'essence et la personnalité de #{character.name}.
    PROMPT
    
    client = OpenAI::Client.new
  
    response = client.images.generate(parameters: {
      model: "dall-e-3",
      prompt: prompt,
      size: "1024x1024",
      quality: "standard"
    })
    
    image_url = response.dig("data", 0, "url")
  
    if image_url
      file = URI.open(image_url)
      character.photo.attach(io: file, filename: "#{character.name.parameterize}.png", content_type: "image/png")
    else
      Rails.logger.error "Failed to generate image for character #{character.id}"
    end
  end  
end
