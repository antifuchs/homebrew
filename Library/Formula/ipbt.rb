require 'formula'

class Ipbt <Formula
  url 'http://www.chiark.greenend.org.uk/~sgtatham/ipbt/ipbt-r8765.tar.gz'
  homepage 'http://www.chiark.greenend.org.uk/~sgtatham/ipbt/'
  md5 'fe9f11cf21d92e53b648d1a64bd129a3'

 depends_on 'ncursesw'

  def install
    system "make"
    bin.install ["ttydump", "ttygrep", "ipbt"]
    man1.install "ipbt.1"
  end
end
