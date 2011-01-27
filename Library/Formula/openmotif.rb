require 'formula'

class Openmotif <Formula
  url 'http://motifzone.com/files/public_downloads/openmotif/2.3/2.3.3/openmotif-2.3.3.tar.gz'
  homepage 'http://motifzone.com'
  md5 'fd27cd3369d6c7d5ef79eccba524f7be'

  def patches
    # Allow UIL to compile on OS X - allegedly fixed in the release after 2.3.3:
    {:p1 => 'http://bugs.motifzone.net/showattachment.cgi?attach_id=259' }
  end

  def install
    ENV.universal_binary
    ENV.j1
    system "./configure", "--disable-debug", "--disable-dependency-tracking",
                          "--prefix=#{prefix}",
                          "--enable-jpeg", "--enable-png", "--enable-xft"
    system "make"
    system "make install"
  end
end
