# Health Check
resource "google_compute_health_check" "http" {
  name = "nginx-http-health-check"

  http_health_check {
    port = 80
  }
}

# Backend Service (USES MIG)
resource "google_compute_backend_service" "default" {
  name      = "nginx-backend-service"
  protocol  = "HTTP"
  port_name = "http"

  backend {
    group = var.instance_group
  }

  health_checks = [google_compute_health_check.http.self_link]
}

# URL Map
resource "google_compute_url_map" "default" {
  name            = "nginx-url-map"
  default_service = google_compute_backend_service.default.self_link
}

# HTTP Proxy
resource "google_compute_target_http_proxy" "default" {
  name    = "nginx-http-proxy"
  url_map = google_compute_url_map.default.self_link
}

# Forwarding Rule (PUBLIC IP)
resource "google_compute_global_forwarding_rule" "default" {
  name       = "nginx-forwarding-rule"
  port_range = "80"
  target     = google_compute_target_http_proxy.default.self_link
}