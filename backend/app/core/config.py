from pydantic import field_validator, model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8")

    app_name: str = "AURA FIT AI"
    environment: str = "development"
    database_url: str = "postgresql://postgres:postgres@localhost:5432/aura_fit_ai"
    jwt_secret: str = "change-me"
    jwt_algorithm: str = "HS256"
    access_token_expire_minutes: int = 60 * 24
    google_client_id: str | None = None
    gemini_api_key: str | None = None
    cors_origins: list[str] | str = ["http://localhost:3000"]

    @field_validator("cors_origins", mode="before")
    @classmethod
    def split_origins(cls, value: list[str] | str) -> list[str]:
        if isinstance(value, str):
            return [item.strip() for item in value.split(",") if item.strip()]
        return value

    @model_validator(mode="after")
    def validate_secret(self) -> "Settings":
        if self.environment == "production" and self.jwt_secret == "change-me":
            raise ValueError("JWT_SECRET must be set for production")
        return self


settings = Settings()
