# Maintainer: dsksnkz
pkgname=ghost-hyprland-git
pkgver=0
pkgrel=1
pkgdesc="Graphical Hyprland Operating system Toolkit (ghOSt Shell) "
arch=('any')
url="https://github.com/dsksnkz/ghOSt"
license=('GPL-3.0')
depends=('hyprland' 'quickshell' 'python' 'python-gobject' 'adwaita-fonts' 'hyprlock')
optdepends=('crunchycleaner-bin: cache cleanup')
makedepends=('git')
provides=('ghost-hyprland')
conflicts=('ghost-hyprland')
source=("ghost::git+https://github.com/dsksnkz/ghOSt.git")
sha256sums=('SKIP')

pkgver() {
    cd ghost
    printf "r%s.%s" "$(git rev-list --count HEAD)" "$(git rev-parse --short HEAD)"
}

package() {
    cd ghost
    install -d "$pkgdir/usr/share/ghost"
    cp -a config scripts install.sh "$pkgdir/usr/share/ghost/"
    install -d "$pkgdir/usr/bin"
    printf '#!/bin/sh\nexec /usr/share/ghost/install.sh "$@"\n' > "$pkgdir/usr/bin/ghost-install"
    chmod 755 "$pkgdir/usr/bin/ghost-install"
}
