require 'formula'

class Logcheck <Formula
  url 'git://git.debian.org/git/logcheck/logcheck.git'
  head "debian/1.3.7"
  version '1.3.7'
  homepage 'http://logcheck.org/'
  md5 ''

  def caveats
    "This installs the logtail and logtail2 programs only."
  end
  

  def install
    system "make -B install DESTDIR=tmp-install-dir"
    bin.install "tmp-install-dir/usr/sbin/logtail"
    bin.install "tmp-install-dir/usr/sbin/logtail2"
  end
end
