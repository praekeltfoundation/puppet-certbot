# List the files in the 'live' path. Note that this only works for the default
# 'live' path: /etc/letsencrypt/live
def contains_certs?(live_dir)
  return false unless File.directory?(live_dir)

  ['cert.pem', 'chain.pem', 'fullchain.pem', 'privkey.pem'].all? do |f|
    File.file?(File.join(live_dir, f))
  end
end

Facter.add(:certbot_live_certs) do
  setcode do
    dirs = Dir.glob('/etc/letsencrypt/live/*').select { |f| contains_certs?(f) }
    dirs.map { |f| File.basename(f) }
  end
end
