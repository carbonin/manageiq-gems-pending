require "awesome_spawn"
require "net/ssh"

module ApplianceConsole
  class SshKeyConfiguration
    PUBLIC_KEY  = "/root/.ssh/id_rsa.pub".freeze
    PRIVATE_KEY = "/root/.ssh/id_rsa".freeze

    attr_accessor :host, :username, :password, :action

    def initialize(options = {})
      options.each { |k, v| public_send("#{k}=", v) }
      @username ||= "root"
    end

    def ask_questions
      ask_for_action
      ask_for_host_info if install_key?
    end

    def activate
      install_key if install_key?
      generate_key if generate_key?
    end

    def key_pair_configured?
      File.exist?(PUBLIC_KEY) && File.exist?(PRIVATE_KEY)
    end

    private

    def install_key?
      action == :install
    end

    def install_key
      raise "No key pair found" unless key_pair_configured?
      public_key = File.read(PUBLIC_KEY)

      Net::SSH.start(host, username, :password => password) do |ssh|
        ssh.exec!("echo \"#{public_key}\" >> ~/.ssh/authorized_keys")
      end
    end

    def generate_key?
      action == :generate
    end

    def generate_key
      params = {
        :t => "rsa",
        :f => "/root/.ssh/id_rsa",
        :N => "",
        :q => nil
      }
      log_and_feedback(__method__) do
        AwesomeSpawn.run!("ssh-keygen", params)
      end
    end

    def ask_for_host_info
      @host     = ask_for_ip_or_hostname("host to install the private key on") 
      @username = ask_for_string("SSH username on #{host}", "root")
      @password = ask_for_password("SSH password for #{username}@#{host}")
    end

    def ask_for_action
      options = {"Generate key pair" => :generate, "Install public key" => :install}
      @action = ask_with_menu("SSH Key action", options)
    end
  end
end
