# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  # All Vagrant configuration is done here. The most common configuration
  # options are documented and commented below. For a complete reference,
  # please see the online documentation at vagrantup.com.

  # Every Vagrant virtual environment requires a box to build off of.
  config.vm.box = "camper"
  config.vm.box_version = ">= 3.0"
  config.vm.box_url = "http://camp.curationexperts.com/vagrant-boxes/dce-boxes.json"

  # provision as 'vagrant' user (not privileged)
  config.vm.provision :shell, privileged: false, path: "bootstrap.sh"

  # Disable automatic box update checking. If you disable this, then
  # boxes will only be checked for updates when the user runs
  # `vagrant box outdated`. This is not recommended.
  # config.vm.box_check_update = false

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  # Add port forwarding for jetty and the rails development server
  config.vm.network "forwarded_port", guest: 8983, host: 8983, auto_correct: true
  config.vm.network "forwarded_port", guest: 8984, host: 8984, auto_correct: true
  config.vm.network "forwarded_port", guest: 3000, host: 3000, auto_correct: true
  
  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  # config.vm.network "private_network", ip: "192.168.33.10"

  # Create a public network, which generally matched to bridged network.
  # Bridged networks make the machine appear as another physical device on
  # your network.
  # config.vm.network "public_network"
  
  # Set the VM hostname
  config.vm.hostname = "heliotrope"
  
  # If true, then any SSH connections made will enable agent forwarding.
  # Default value: false
  # config.ssh.forward_agent = true

  # Share an additional folder to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  # config.vm.synced_folder "../data", "/vagrant_data"
  # config.vm.synced_folder ".", "/vagrant", id: "vagrant-root",
     # owner: "vagrant",
     # group: "vagrant",
     # mount_options: ["dmode=775,fmode=664"]

  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.
  # Example for VirtualBox:
  #
  config.vm.provider "virtualbox" do |vb|
    # Don't boot with headless mode
    #vb.gui = true
    #
    # Use VBoxManage to customize the VM. For example to change memory:
    vb.customize ["modifyvm", :id, "--memory", "4096"]
    vb.customize ["modifyvm", :id, "--cpus", "2"]
    vb.customize ["modifyvm", :id, "--name", "Heliotrope Dev VM"]
    # vb.customize ["setextradata", :id, "VBoxInternal2/SharedFoldersEnableSymlinksCreate/v-root", "1"]
  end
  #
  # View the documentation for the provider you're using for more
  # information on available options.

end
