# script to replace salt provisioner that doesn't work anymore (as of sep 2022)
# this only works with ubuntu, but should support any version & cpu arch

# exit when any command fails
set -e

# echo an error message before exiting
trap 'echo "\"${last_command}\" last command finished with exit code $?."' EXIT

# Set APT to non-interactive
export DEBIAN_FRONTEND=noninteractive

# System update
apt-get update

# Install pre reqs
apt-get install -y curl lsb-release sudo locales software-properties-common

ARCH=$(dpkg --print-architecture)
REL=$(lsb_release -r -s)
CODE=$(lsb_release -c -s)

echo "Ubuntu $REL/$CODE running on $ARCH as $SUDO_USER"

# For Docker (root/empty) we need an ubuntu user
if [ "$SUDO_USER" == "root" ] || [ -z "$SUDO_USER" ]; then
  HOME_DIR="/root"
  useradd ubuntu --shell /bin/bash --create-home && usermod -a -G sudo ubuntu && echo 'ALL ALL = (ALL) NOPASSWD: ALL' >> /etc/sudoers
else
  HOME_DIR="/home/$SUDO_USER"
fi

echo "Installing Salt"

# Install salt minion - https://docs.saltproject.io/salt/install-guide/en/latest/topics/install-by-operating-system/ubuntu.html
mkdir -p /etc/apt/keyrings/
curl -fsSL -o /etc/apt/keyrings/salt-archive-keyring-2023.gpg https://repo.saltproject.io/salt/py3/ubuntu/$REL/$ARCH/SALT-PROJECT-GPG-PUBKEY-2023.gpg
echo "deb [signed-by=/etc/apt/keyrings/salt-archive-keyring-2023.gpg arch=$ARCH] https://repo.saltproject.io/salt/py3/ubuntu/$REL/$ARCH/latest $CODE main" | tee /etc/apt/sources.list.d/salt.list
apt-get update
apt-get install -y salt-minion

echo "Configuring Salt"

# Symlink to default salt, pillar and minion config locations
ln -sf "$HOME_DIR"/salt /srv/salt
ln -sf "$HOME_DIR"/pillar /srv/pillar
cp "$HOME_DIR"/minion.config /etc/salt/minion

echo "Applying Salt"

# Run masterless salt
salt-call --local state.apply

echo "Cleaning Up"

# Clean up the logs from building
find /var/log -name "*.log" | xargs truncate -s 0

# Clean up salt files
rm -rf "$HOME_DIR"/salt /srv/salt "$HOME_DIR"/pillar /srv/pillar /etc/salt/minion "$HOME_DIR"/minion.config 

# Clean up packages
apt-get purge salt-common salt-minion -y
apt-get autoremove -y
apt-get clean -y

# Upgrade
apt-get dist-upgrade -yq

exit 0

