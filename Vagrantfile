# -*- mode: ruby -*
# vi: set ft=ruby :

base_ip = '192.168.2'
matrix = [
  { hostname: 'centos7',    ip: "#{base_ip}.10", box: 'geerlingguy/centos7' },
  { hostname: 'rocky8',     ip: "#{base_ip}.20", box: 'geerlingguy/rockylinux8' },
  { hostname: 'rocky9',     ip: "#{base_ip}.30", box: 'rockylinux/9' },
  { hostname: 'ubuntu2004', ip: "#{base_ip}.40", box: 'geerlingguy/ubuntu2004' },
  { hostname: 'ubuntu2204', ip: "#{base_ip}.50", box: 'ubuntu/jammy64' }
]

Vagrant.configure('2') do |config|
  # Base VM OS configuration.
  config.vm.box_check_update = false
  config.ssh.insert_key = false
  config.vm.synced_folder '.', '/vagrant', disabled: true
  # Do not automatically update the guest addtitions
  config.vbguest.auto_update = false if Vagrant.has_plugin?('vagrant-vbguest')

  # General VirtualBox VM configuration.
  config.vm.provider :virtualbox do |v|
    v.memory = 512
    v.cpus = 1
    v.linked_clone = true
    v.customize ['modifyvm', :id, '--natdnshostresolver1', 'on']
    v.customize ['modifyvm', :id, '--ioapic', 'on']
  end

  matrix.each do |machine|
    config.vm.define machine[:hostname] do |v|
      v.vm.hostname = "#{machine[:hostname]}.test"
      v.vm.network :private_network, ip: machine[:ip]
      v.vm.box = machine[:box]
    end
  end

  # config.vm.define "memcached" do |memcached|
  #   memcached.vm.hostname = "memcached.test"
  #   memcached.vm.network :private_network, ip: "192.168.2.7"
  #
  #   # Run Ansible provisioner once for all VMs at the end.
  #   memcached.vm.provision "ansible" do |ansible|
  #     ansible.playbook = "configure.yml"
  #     ansible.inventory_path = "inventories/vagrant/inventory.ini"
  #     ansible.limit = "all"
  #     ansible.extra_vars = {
  #       ansible_user: 'vagrant',
  #       ansible_ssh_private_key_file: "~/.vagrant.d/insecure_private_key"
  #     }
  #    end
  # end
end
