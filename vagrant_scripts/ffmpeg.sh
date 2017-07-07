#!/bin/sh
# see issue https://github.com/mlibrary/heliotrope/issues/359

echo "Setting up ffmpeg for heliotrope"

echo "installing ffmpeg dependencies..."
# https://trac.ffmpeg.org/wiki/CompilationGuide/Ubuntu#GettheDependencies
# discounting non-server packages. Note wget and build-essential are already installed by other scripts
PACKAGES="autoconf automake libass-dev libfreetype6-dev libtheora-dev libtool libvorbis-dev pkg-config texinfo zlib1g-dev"
sudo apt-get -y install $PACKAGES > /dev/null 2>&1

echo "installing yasm to speed up ffmpeg build..."
sudo sudo apt-get install yasm > /dev/null 2>&1

echo "installing ffmpeg libraries..."
LIBRARIES="libfdk-aac-dev libmp3lame-dev libopus-dev libvpx-dev libx264-dev"
sudo apt-get -y install $LIBRARIES > /dev/null 2>&1

mkdir /home/vagrant/ffmpeg_sources
cd /home/vagrant/ffmpeg_sources
wget http://ffmpeg.org/releases/ffmpeg-snapshot.tar.bz2 > /dev/null 2>&1
tar xjvf ffmpeg-snapshot.tar.bz2 > /dev/null 2>&1
cd ffmpeg

echo "building ffmpeg..."
PATH="$HOME/bin:$PATH" PKG_CONFIG_PATH="$HOME/ffmpeg_build/lib/pkgconfig" ./configure \
  --prefix="$HOME/ffmpeg_build" \
  --pkg-config-flags="--static" \
  --extra-cflags="-I$HOME/ffmpeg_build/include" \
  --extra-ldflags="-L$HOME/ffmpeg_build/lib" \
  --bindir="$HOME/bin" \
  --extra-libs=-ldl \
  --enable-gpl \
  --enable-nonfree \
  --enable-libfdk_aac \
  --enable-libmp3lame \
  --enable-libopus \
  --enable-libvorbis \
  --enable-libvpx \
  --enable-libx264

PATH="$HOME/bin:$PATH" make
make -s install
hash -r
