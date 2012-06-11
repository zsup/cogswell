#
# Hey there. This is how I set up my BeagleBone.
#

# First, connect to the BeagleBone over SSH, with tunneling for rmate.
# Note: This is to be typed on the client computer, not the BeagleBone.
ssh -R 52698:localhost:52698 root@beaglebone.local

# First, let's secure the BeagleBone.
passwd root
# Set password to whatever.

# Let's test the network and DNS servers.
ifconfig eth0
ping google.com

# Set the timezone
ls -lr /usr/share/zoneinfo/ # Just to see what our options are
rm /etc/localtime
ln -s /usr/share/zoneinfo/America/Chicago /etc/localtime # Or whatever.

# Okay, let's update everything!
opkg update
opkg upgrade

# Install Ruby (for rmate)
# NOTE: Should check that this is still the latest version at:
# http://www.angstrom-distribution.org/repo/?pkgname=ruby
wget http://www.angstrom-distribution.org/feeds/next/ipk/eglibc/armv7a/base/ruby_1.8.7-p302-r2.1.9_armv7a.ipk
opkg install ruby_1.8.7-p302-r2.1.9_armv7a.ipk

# May require installing some dependencies manually. Here's what I did:
wget http://www.angstrom-distribution.org/feeds/next/ipk/eglibc/armv7a/base/libgdbm3_1.8.3-r5.9_armv7a.ipk
wget http://www.angstrom-distribution.org/feeds/next/ipk/eglibc/armv7a/base/libreadline5_5.2-r8.9_armv7a.ipk
wget http://www.angstrom-distribution.org/feeds/next/ipk/eglibc/armv7a/base/libtk8.5-0_8.5.8-r3.9_armv7a.ipk
wget http://www.angstrom-distribution.org/feeds/next/ipk/eglibc/armv7a/base/libtcl8.5-0_8.5.8-r9.9_armv7a.ipk
opkg install libgdbm3_1.8.3-r5.9_armv7a.ipk
opkg install libreadline5_5.2-r8.9_armv7a.ipk
opkg install libtk8.5-0_8.5.8-r3.9_armv7a.ipk
opkg install libtcl8.5-0_8.5.8-r9.9_armv7a.ipk

# Then let's clean up.
rm libgdbm3_1.8.3-r5.9_armv7a.ipk 
rm libreadline5_5.2-r8.9_armv7a.ipk 
rm libtcl8.5-0_8.5.8-r9.9_armv7a.ipk 
rm libtk8.5-0_8.5.8-r3.9_armv7a.ipk 
rm ruby_1.8.7-p302-r2.1.9_armv7a.ipk 

# Set up rmate for remote text editing through TextMate.
# NOTE: This should be typed on the computer-side, not on the BeagleBone side.
scp /Applications/TextMate\ 2.app/Contents/Frameworks/Preferences.framework/Resources/rmate root@beaglebone.local:/usr/bin

# Install coffeescript.
cd /var/lib/cloud9/
npm -g install coffee-script

# Fix the pinmuxing so that XBee can communicate over serial.
# NOTE: In theory I don't have to do this because it's part of the app.coffee script.
echo 20 > /sys/kernel/debug/omap_mux/uart1_rxd
echo 0 > /sys/kernel/debug/omap_mux/uart1_txd

# If we need to kill the cogswell process, we should do so like so:
systemctl kill cogswell.service

# STILL TO DO:
# Create a cronjob to automate updates. NOTE: Gonna skip this one for now.

# Set up wireless internet.
