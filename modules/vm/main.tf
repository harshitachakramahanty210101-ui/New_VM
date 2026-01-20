resource "google_compute_instance_template" "this" {
  name_prefix  = "${var.vm_name}-template-"
  machine_type = var.machine_type

  disk {
    source_image = "debian-cloud/debian-12"
    auto_delete  = true
    boot         = true
  }

  network_interface {
    subnetwork = var.subnet_self_link
  }

  metadata = {
    enable-oslogin = "TRUE"
  }

  metadata_startup_script = file("${path.module}/startup.sh")

  tags = ["http-server"]
}

resource "google_compute_instance_group_manager" "this" {
  name               = "${var.vm_name}-mig"
  zone               = var.zone
  base_instance_name = var.vm_name
  target_size        = 1

  version {
    instance_template = google_compute_instance_template.this.self_link
  }
}