# Instructions derived from http://www.itworld.com/software/304992/install-googles-chrome-browser-ubuntu-1210

execute "wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -" do
  not_if 'apt-key list | grep "C07CB649"'
end

apt_repository "google-chrome" do
  uri "http://dl.google.com/linux/chrome/deb/"
  distribution "stable"
  components ["main"]
  action :add
end

package "google-chrome-stable"