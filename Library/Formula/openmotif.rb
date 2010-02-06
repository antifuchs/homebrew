require 'formula'

class Openmotif <Formula
  url 'http://www.motifzone.net/files/public_downloads/openmotif/2.3/2.3.2/openmotif-2.3.2.tar.gz'
  homepage 'http://www.motifzone.net'
  md5 ''

# depends_on 'cmake'

  def install
    ENV.universal_binary   # Many motif-using programs don't like 64-bit mode.
    
    system "./configure", "--prefix=#{prefix}", "--disable-debug", "--disable-dependency-tracking"
#   system "cmake . #{std_cmake_parameters}"
    system "make install"
  end
end
