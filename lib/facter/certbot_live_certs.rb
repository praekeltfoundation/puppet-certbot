# List the files in the 'live' path. Note that this only works for the default
# 'live' path: /etc/letsencrypt/live
Facter.add(:certbot_live_certs) do
  setcode { Dir.glob('/etc/letsencrypt/live/*').map { |f| File.basename(f) } }
end
