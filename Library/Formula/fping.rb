require 'formula'

class Fping <Formula
  url 'http://fping.sourceforge.net/download/fping.tar.gz'
  version '2.4b2_to-ipv6'
  homepage 'http://fping.sourceforge.net/'
  md5 'd5e8be59e307cef76bc479e1684df705'

# depends_on 'cmake'

  def caveats
    "To run fping as a normal user, you must change it to setuid root:
    
      chmod u+s #{sbin}/fping
      sudo chown root #{sbin}/fping"
  end

  def install
    system "./configure", "--prefix=#{prefix}", "--disable-debug", "--disable-dependency-tracking"
#   system "cmake . #{std_cmake_parameters}"
    system "make install"
  end
end
