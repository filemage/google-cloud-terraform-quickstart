resource "google_secret_manager_secret" "database_password" {
  secret_id = "filemage-database-password"

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "database_password" {
  secret      = google_secret_manager_secret.database_password.id
  secret_data = var.pg_password
}

resource "google_secret_manager_secret_iam_policy" "database_password_read_policy" {
  project     = google_secret_manager_secret.database_password.project
  secret_id   = google_secret_manager_secret.database_password.secret_id
  policy_data = data.google_iam_policy.instance_read_secret.policy_data
}

# The application secret is used to sign session cookies.
resource "random_string" "application_secret" {
  length           = 128
  special          = true
}

resource "google_secret_manager_secret" "application_secret" {
  secret_id = "filemage-application-secret"

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "application_secret" {
  secret      = google_secret_manager_secret.application_secret.id
  secret_data = random_string.application_secret.result
}

resource "google_secret_manager_secret_iam_policy" "application_secret" {
  project     = google_secret_manager_secret.application_secret.project
  secret_id   = google_secret_manager_secret.application_secret.secret_id
  policy_data = data.google_iam_policy.instance_read_secret.policy_data
}
