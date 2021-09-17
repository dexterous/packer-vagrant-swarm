source "vagrant" "fedora" {
  source_path  = "generic/fedora34"
  provider     = "virtualbox"
  communicator = "ssh"

  box_name = "fedora-docker"

  template = "./template/Vagrantfile.tmpl"

  add_force = true
}

build {
  sources = ["source.vagrant.fedora"]

  provisioner "shell" {
    script          = "./script/install-docker-fedora.sh"
    execute_command = "echo 'vagrant' | sudo -S sh -c '{{ .Vars }} {{ .Path }}'"
  }
}
