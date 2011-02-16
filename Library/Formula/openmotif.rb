require 'formula'

class Openmotif <Formula
  url 'http://motifzone.com/files/public_downloads/openmotif/2.3/2.3.3/openmotif-2.3.3.tar.gz'
  homepage 'http://motifzone.com'
  md5 'fd27cd3369d6c7d5ef79eccba524f7be'

  depends_on 'jpeg'

  def patches
    {:p1 => [
        # Allow UIL to compile on OS X - allegedly fixed in the release after 2.3.3:
        'http://bugs.motifzone.net/showattachment.cgi?attach_id=259', 
        # Use the correct freetype header for configure:
        'https://gist.github.com/raw/829781/e75f73b7c34f1e16ad0d811ec4f32229418fb0ce/gistfile1.txt'
     ]}
  end

  def install
    ENV.universal_binary
    ENV.j1
    ENV.gcc_4_2    # llvm-gcc refuses to link the i386 platform libraries.
    system "./configure", "--disable-debug", "--disable-dependency-tracking",
                          "--prefix=#{prefix}",
                          "--enable-jpeg", "--enable-png", "--enable-xft",
			  "--with-freetype-config=/usr/X11/bin/freetype-config"
    system "make"
    system "make install"
  end
end
