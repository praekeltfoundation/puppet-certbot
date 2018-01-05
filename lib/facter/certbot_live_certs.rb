# List the files in the 'live' path. Note that this only works for the default
# 'live' path: /etc/letsencrypt/live
def contains_certs?(live_dir)
  return false if !File.directory?(live_dir)

  ['cert.pem', 'chain.pem', 'fullchain.pem', 'privkey.pem'].all? do |f|
    File.file?(File.join(live_dir, 'fullchain.pem'))
  end
end

Facter.add(:certbot_live_certs) do
  setcode do
    Dir.glob('/etc/letsencrypt/live/*').select do
      |f| contains_certs?(f)
    end.map { |f| File.basename(f) }
  end
end
