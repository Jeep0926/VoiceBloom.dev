# frozen_string_literal: true

class VoiceConditionLogsController < ApplicationController
  before_action :authenticate_user! # ログイン必須にする

  def show
    # (このアクションは後のタスクで、分析結果表示を実装)
    @voice_condition_log = current_user.voice_condition_logs.find(params[:id])
    # @analysis_result = ... (FastAPIからの結果など)
  end

  def new
    # 新しい VoiceConditionLog オブジェクトを作成 (フォームで使用)
    @voice_condition_log = current_user.voice_condition_logs.build
    # MVPでは固定フレーズを使用
    @fixed_phrase = '今日も一日頑張りましょう！'
  end

  def create
    # (このアクションは後のタスクで、JSからの音声データ受信とFastAPI連携を実装)
    # 現時点では、成功/失敗のダミーリダイレクト先だけ設定しておく
    redirect_to root_path, notice: '（仮）記録処理中...' # rubocop:disable Rails/I18nLocaleTexts
  end

  # (Strong Parameters は create アクション実装時に定義)
  # def voice_condition_log_params
  #   params.require(:voice_condition_log).permit(:recorded_audio, :phrase_text_snapshot)
  # end
end
