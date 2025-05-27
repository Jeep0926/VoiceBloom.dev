import { Application } from "@hotwired/stimulus"
import WebAudioRecorderController from "./controllers/web_audio_recorder_controller.js"

const application = Application.start()
application.debug = true
window.Stimulus = application

application.register("web-audio-recorder", WebAudioRecorderController)
export { application }