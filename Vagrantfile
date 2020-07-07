# frozen_string_literal: true

# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version.
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.hostname = "heliotrope"

  config.vm.box = "bento/ubuntu-18.04"

  config.ssh.username = 'vagrant'
  config.ssh.password = 'vagrant'

  # provision as 'vagrant' user (not privileged)
  # config.vm.provision :shell, privileged: false, path: "bootstrap.sh"

  # port forwarding jetty (8983/4), the rails development server (3000) and MySQL (3306)
  config.vm.network "forwarded_port", guest: 8983, host: 8983, auto_correct: true
  config.vm.network "forwarded_port", guest: 8984, host: 8984, auto_correct: true
  config.vm.network "forwarded_port", guest: 3000, host: 3000, auto_correct: true
  config.vm.network "forwarded_port", guest: 3306, host: 3306, auto_correct: true

  config.vm.provider "virtualbox" do |vb|
    vb.customize ["modifyvm", :id, "--memory", "8000"]
    vb.customize ["modifyvm", :id, "--cpus", "4"]
    vb.customize ["modifyvm", :id, "--name", "Heliotrope Dev VM"]
  end

  shared_dir = "/vagrant"

  # install scripts partly stolen from https://github.com/samvera-labs/samvera-vagrant
  config.vm.provision :shell, path: "./vagrant_scripts/bootstrap.sh", args: shared_dir
  config.vm.provision :shell, path: "./vagrant_scripts/java.sh"
  config.vm.provision :shell, path: "./vagrant_scripts/ruby.sh"
  config.vm.provision :shell, path: "./vagrant_scripts/mysql.sh"
  config.vm.provision :shell, path: "./vagrant_scripts/fits.sh", args: shared_dir, privileged: false
  config.vm.provision :shell, path: "./vagrant_scripts/heliotrope.sh"
end
