class Authority
  attr_reader :name, :dir, :serial_number

  def self.find(ca_org)
    self.new(ca_org).open
  end

  def initialize(name)
    @name = name
    @dir = File.join(PROJECT_ROOT, "build", name)
  end

  def open
    FileUtils.mkpath(dir)
    self
  end

  def update
    build_root
    build_intermediate
    self
  end

  def issue(domain)
    write_certs(domain, terminal_profile) do |cert|
      cert.subject.common_name = domain
      cert.subject.organization = name
      cert.key_material.generate_key
      cert.parent = find_intermediate
    end
  end

  private

  def write_certs(cert_name, profile)
    sn = serial_number
    cert = CertificateAuthority::Certificate.new
    cert.serial_number.number = sn
    yield cert
    cert.sign! profile
    prefix = File.join(dir, cert_name.to_s)
    puts "Writing cert ##{sn} #{cert.subject.common_name} to #{prefix}"
    File.write("#{prefix}.key", cert.key_material.private_key)
    File.write("#{prefix}.pub", cert.key_material.public_key)
    File.write("#{prefix}.pem", to_bundle(cert))
    cert
  end

  def to_bundle(cert)
    [].tap do |certs|
      certs << cert
      certs << (cert = cert.parent) while cert != cert.parent
    end.map(&:to_pem).join
  end

  def serial_number
    db.transaction { db[:serial_number] = db[:serial_number].to_i + 1 }
  end

  def find_cert(name)
    path = File.join(dir, "#{name}.pem")
    return unless File.exist?(path)
    CertificateAuthority::Certificate.from_openssl(
      OpenSSL::X509::Certificate.new(File.read path)
    ).tap do |cert|
      cert.key_material.private_key = OpenSSL::PKey::RSA.new(
        File.read(File.join(dir, "#{name}.key"))
      )
    end
  end

  def find_intermediate
    if cert = find_cert(:ca)
      cert.parent = find_cert(:root)
      cert
    else
      update
      @ca
    end
  end

  def build_root
    @root = write_certs(:root, root_profile) do |cert|
      cert.subject.common_name = "#{name}.root"
      cert.subject.organization = name
      cert.key_material.generate_key
      cert.signing_entity = true
    end
  end

  def build_intermediate
    @ca = write_certs(:ca, intermediate_profile) do |cert|
      cert.subject.common_name = "ca.#{name}.root"
      cert.subject.organization = name
      cert.key_material.generate_key
      cert.signing_entity = true
      cert.parent = @root
    end
  end

  def db
    @db ||= PStore.new File.join(dir, "db.pstore")
  end

  def root_profile
    {
      "extensions" => {
        "keyUsage" => {"usage" => ["critical", "keyCertSign"] }
      }
    }
  end

  def intermediate_profile
    root_profile
  end

  def terminal_profile
    {
      "extensions" => {
        "keyUsage" => {
          "usage" => ["critical", "digitalSignature", "keyEncipherment"]
        },
        "extendedKeyUsage" => {
          "usage" => ["serverAuth", "clientAuth"]
        }
      }
    }
  end
end
