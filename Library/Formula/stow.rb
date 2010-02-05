require 'formula'

class Stow <Formula
  url 'ftp://ftp.gnu.org/gnu/stow/stow-1.3.3.tar.gz'
  homepage 'http://www.gnu.org/software/stow/'
  md5 ''

# depends_on 'cmake'

  def install
    system "./configure", "--prefix=#{prefix}", "--disable-debug", "--disable-dependency-tracking"
    system "make install"
  end
end
