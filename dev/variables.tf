variable "supabase_url" {
  description = "Supabase URL for the AI Tutor Backend"
  type        = string
  sensitive   = true
}

variable "supabase_service_key" {
  description = "Supabase service key for the AI Tutor Backend"
  type        = string
  sensitive   = true
}

variable "openai_api_key" {
  description = "OpenAI API key for the AI Tutor Backend"
  type        = string
  sensitive   = true
}

variable "eleven_api_key" {
  description = "ElevenLabs API key for text-to-speech"
  type        = string
  sensitive   = true
}

variable "eleven_voice_id" {
  description = "ElevenLabs voice ID for text-to-speech"
  type        = string
  sensitive   = true
}

variable "db_host" {
  description = "Database host for the AI Tutor Backend"
  type        = string
  sensitive   = true
}

variable "db_name" {
  description = "Database name for the AI Tutor Backend"
  type        = string
  sensitive   = true
}

variable "db_user" {
  description = "Database username for the AI Tutor Backend"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Database password for the AI Tutor Backend"
  type        = string
  sensitive   = true
}

variable "wp_site_url" {
  description = "WordPress site URL for the AI Tutor Backend"
  type        = string
  sensitive   = true
}

variable "wp_api_username" {
  description = "WordPress API username for the AI Tutor Backend"
  type        = string
  sensitive   = true
}

variable "wp_api_application_password" {
  description = "WordPress API application password for the AI Tutor Backend"
  type        = string
  sensitive   = true
}

variable "google_credentials_json" {
  description = "Google Cloud Service Account credentials JSON for the AI Tutor Backend"
  type        = string
  sensitive   = true
}
