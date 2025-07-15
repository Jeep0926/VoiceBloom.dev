# frozen_string_literal: true

class CharacterGeneratorService
  def initialize(user)
    @user = user
  end

  def call
    # TODO: 基準値を元にプロンプトを生成し、画像生成AIを呼び出すロジックをここに実装
    Rails.logger.info "Generating character for User ID: #{@user.id}..."
    # MVPでは、ダミー画像をアタッチする処理をシミュレート
    # (この処理は、ダミー画像ファイルが app/assets/images/dummy_character.png にあると仮定)
    # dummy_image_path = Rails.root.join('app', 'assets', 'images', 'dummy_character.svg')
    # if File.exist?(dummy_image_path)
    #   @user.character_images.create!(
    #     expression: 'neutral',
    #     image: {
    #       io: File.open(dummy_image_path),
    #       filename: 'neutral_character.svg',
    #       content_type: 'image/svg+xml'
    #     }
    #   )
    # end
    Rails.logger.info "Character generation process finished for User ID: #{@user.id}."
    true # 成功した場合はtrueを返す
  end
end
