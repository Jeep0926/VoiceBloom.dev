// app/javascript/application.js
import { Application } from "@hotwired/stimulus"
import WebAudioRecorderController from "./controllers/web_audio_recorder_controller.js"
import AnalysisUpdaterController from "./controllers/analysis_updater_controller.js"
import TabsController from "./controllers/tabs_controller.js";

const application = Application.start()
application.debug = true // 開発中はtrueでOK
// window.Stimulus = application // グローバルに置く必要がなければ削除しても良いことも

application.register("web-audio-recorder", WebAudioRecorderController)
application.register("analysis-updater", AnalysisUpdaterController)
application.register("tabs", TabsController);

import "./channels" // Action Cableのチャネルを読み込む

// export { application } // Stimulusアプリケーションインスタンスをエクスポート (他のモジュールから参照する場合)