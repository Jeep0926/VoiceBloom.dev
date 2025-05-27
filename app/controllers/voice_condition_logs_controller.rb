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
    @voice_condition_log = current_user.voice_condition_logs.build(voice_condition_log_params)
    # Railsが自動で analyzed_at を created_at/updated_at と同じように設定してくれるわけではないので、
    # 明示的に設定するか、コールバックで設定する。ここでは分析完了時を想定し、
    # FastAPI連携時にFastAPIから返ってきた時刻を使うか、ここで Time.current を入れる。
    # MVPでは一旦、ファイル受信時刻を分析時刻とする。
    @voice_condition_log.analyzed_at = Time.current

    # phrase_text_snapshot は params[:voice_condition_log][:phrase_text_snapshot] から来るはず
    # もしJSから送られていない場合、@fixed_phrase を使うなどのフォールバックも検討できるが、JS側でしっかり送るのが基本。

    if @voice_condition_log.save
      # ★★★ ここでFastAPIへの連携処理を呼び出す (次のタスク 2-10a 以降) ★★★
      # analyze_voice_with_fastapi(@voice_condition_log) # 仮のメソッド呼び出し

      # FastAPI連携がないMVPの段階では、保存成功したら結果表示ページへリダイレクト
      redirect_to @voice_condition_log, notice: '声のコンディション記録を受け付けました。分析結果をお待ちください。' # rubocop:disable Rails/I18nLocaleTexts
    else
      # バリデーションエラーなどで保存失敗した場合
      @fixed_phrase = '今日も一日頑張りましょう！'
      render :new, status: :unprocessable_entity
    end
  end

  private

  # (Strong Parameters は create アクション実装時に定義)
  def voice_condition_log_params
    params.require(:voice_condition_log).permit(:recorded_audio, :phrase_text_snapshot)
  end
end
