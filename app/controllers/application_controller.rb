# frozen_string_literal: true

class ApplicationController < ActionController::Base
  def hello
    render html: 'Hello from VoiceBloom on Docker (Rails server is running)!'
  end
end
