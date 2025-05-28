from pydantic import BaseModel
from typing import Optional

class VoiceFeaturesResponse(BaseModel):
    pitch_value: Optional[float] = None
    tempo_value: Optional[float] = None
    volume_value: Optional[float] = None
    duration_seconds: Optional[float] = None
    analysis_error_message: Optional[str] = None
    