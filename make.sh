
#!/bin/bash

# Setup building environment

# sudo apt-get install git-core gnupg ccache lzop flex bison gperf build-essential zip curl zlib1g-dev zlib1g-dev:i386 libc6-dev lib32ncurses5 lib32z1 lib32bz2-1.0 lib32ncurses5-dev x11proto-core-dev libx11-dev:i386 libreadline6-dev:i386 lib32z-dev libgl1-mesa-glx:i386 libgl1-mesa-dev g++-multilib mingw32 tofrodos python-markdown libxml2-utils xsltproc readline-common libreadline6-dev libreadline6 lib32readline-gplv2-dev libncurses5-dev lib32readline5 lib32readline6 libreadline-dev libreadline6-dev:i386 libreadline6:i386 bzip2 libbz2-dev libbz2-1.0 libghc-bzlib-dev lib32bz2-dev libsdl1.2-dev libesd0-dev squashfs-tools pngcrush schedtool libwxgtk2.8-dev python

# make a working directory

mkdir port
cd port

# Download firmware

wget https://mirrors.lolinet.com/firmware/motorola/tundra_retcn/official/RETCN/XT2243-2_TUNDRA_RETCN_12_S3SJ32.1-79-10_subsidy-DEFAULT_regulatory-DEFAULT_CFC.xml.zip

# Get a random zip file
random_zip=$(ls *.zip | shuf -n 1)

# Rename the random zip file to "firmware.zip"
mv "$random_zip" firmware.zip

unzip firmware.zip

# Merge sparsechunk images

for i in sparsechunk.*; do
  cat $i >> super.img
done

# Convert merged super.img to raw format

simg2img super.img super.raw.img
rm super.img

# Remove firmware.zip to make more space

rm firmware.zip

# Unpack super.raw.img

unzip super.raw.img

# Rename images

mv system_a.img system.img
mv product_a.img product.img
mv system_ext_a.img system_ext.img

# Create new folders

mkdir system_new system product system_ext

# Create blank system_new.img

dd if=/dev/zero of=system_new.img bs=1M count=3072

# Format system_new.img

mkfs.ext4 system_new.img
tune2fs -c 3072 system_new.img

# Mount images

mount system_new.img system_new
mount system.img system
mount product.img product
mount system_ext.img system_ext

# Check if the user is root
if [ ! "$(whoami)" == "root" ]; then
  echo "You must be root to run this script."
  exit 1
fi

# Remove the Drive folder and file
rm -rf /product/app/Drive*

# Print a success message
echo "These folders and files have been removed."

# Copy files

rsync -a --copy-links --verbose system/ system_new/
rsync -a --copy-links --verbose product/ system_new/
rsync -a --copy-links --verbose system_ext/ system_new/

# Sync

sync

# Create the symlink
ln -s /vendor/moto /system_new/product/app/TimeWeather
ln -s /vendor/moto /system_new/product/priv-app/MotoAppForecast
ln -s /vendor/moto /system_new/product/priv-app/MotoAppUIRefresh
ln -s /vendor/moto /system_new/product/priv-app/MotoDesktop
ln -s /vendor/moto /system_new/product/priv-app/MotoDisplayV6
ln -s /vendor/moto /system_new/product/priv-app/MotoFaceUnlockArcSoft
ln -s /vendor/moto /system_new/product/priv-app/MotoIntelligence
ln -s /vendor/moto /system_new/product/priv-app/MotoLeanbackLauncher
ln -s /vendor/moto /system_new/product/priv-app/MotoLiveWallpaper3Prebuilt-chroma_plume
ln -s /vendor/moto /system_new/product/priv-app/MotoLiveWallpaper3Prebuilt-titan
ln -s /vendor/moto /system_new/product/priv-app/MotoLiveWallpaper3Prebuilt-twilight_twist
ln -s /vendor/moto /system_new/product/priv-app/MotoStylus
ln -s /vendor/moto /system_new/product/priv-app/MotoTour
ln -s /vendor/moto /system_new/product/priv-app/MyKey
ln -s /vendor/moto /system_new/product/priv-app/PrcGallery2
ln -s /cust /system_new/product/priv-app/DeviceMigration
ln -s /cust /system_new/product/preinstall/Blossom
ln -s /cust /system_new/product/preinstall/Calm
ln -s /cust /system_new/product/preinstall/Curl
ln -s /cust /system_new/product/preinstall/Dusk
ln -s /cust /system_new/product/preinstall/Neon
ln -s /cust /system_new/product/preinstall/PrcCalculator
ln -s /cust /system_new/product/preinstall/PrcCompass

# Unmount images

umount system_new
umount system
umount product
umount system_ext


# Get the path to the brotli binary
brotli_path=$(which brotli)

# Compress the system_new.img file to a compressed file with quality factor 11
brotli --compress -q 11 system_new.img -o system.new.dat.br


# Get the path to the zip binary
zip_path=$(which zip)

# Create a zip file
zip -r system.zip system.new.dat.br system.patch.dat system.transfer.list


# Upload system_new.img to Source Forge

# Get the file path of the system_new.img file
file_path="./system.zip"

# Get the SourceForge username and password
sourceforge_username="joy569569"
sourceforge_password="Arijit@12345"

# Connect to SourceForge using SFTP
ssh joy569569@frs.sourceforge.net

# Upload the system_new.img file
scp -r $file_path joy569569@frs.sourceforge.net:/home/frs/project/testing-project/testing
