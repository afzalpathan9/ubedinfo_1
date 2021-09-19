###Define Service Provider and Project and region and zone

provider "google" {
  project = "tasmahiti"
  region  = "us-west2"
  zone    = "us-west2-a"
}


##Saving state in tfsate create buckets
terraform {
  backend "gcs" {
    bucket = "ubedinfo-1-tfstate"
    prefix = "terraform/state"
  }
}


##Create Service account

resource "google_service_account" "service_account" {
  account_id   = "svc-ubedinfo"
  display_name = "svc-ubedinfo"
}

##Create iam binding and assign role 
resource "google_project_iam_binding" "project" {
  project = "tasmahiti"
  role    = "roles/editor"

  members = [
    "serviceAccount:svc-ubedinfo@tasmahiti.gserviceaccount.com",
  ]
}


##Enable services requierd to work on
variable "gcp_service_list" {
  description ="The list of apis necessary for the project"
  type = list(string)
  default = [
        "iam.googleapis.com",
		"compute.googleapis.com",
		"dataflow.googleapis.com",
		"iam.googleapis.com",
		"stackdriver.googleapis.com",
		##"bigquerystorage.googleapis.com",
		"bigquery.googleapis.com"
  ]
  
 ## disable_dependent_services=true
}



resource "google_project_service" "gcp_services" {
  for_each = toset(var.gcp_service_list)
  project = "tasmahiti"
  service = each.key
  disable_dependent_services = true
}



## Create Bucket

resource "google_storage_bucket" "ubedinfo-buckets" {
  name          = "ubedinfo-demo-bucket"
  location      = "US"
  force_destroy = true

  lifecycle_rule {
    condition {
      age = 3
    }
    action {
      type = "Delete"
    }
  }
}

##Create VM instances

resource "google_compute_instance" "vm_instance" {
  name         = "terraform-instance"
  machine_type = "f1-micro"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  network_interface {
    # A default network is created for all GCP projects
    network = "default"
    access_config {
    }
  }
}

##Create VPC network 

resource "google_compute_network" "vpc_network" {
  name                    = "terraform-network"
  auto_create_subnetworks = "true"
}
