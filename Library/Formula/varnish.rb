require 'formula'

class Varnish <Formula
  url 'http://downloads.sourceforge.net/project/varnish/varnish/2.0.6/varnish-2.0.6.tar.gz'
  homepage 'http://varnish.projects.linpro.no/'
  md5 'd91dc21c636db61c69b5e8f061c5bb95'

  def skip_clean? path
    # Do not strip varnish binaries: Otherwise, the magic string end pointer isn't found.
    true
  end

  def install
    system "./configure", "--prefix=#{prefix}", "--localstatedir=#{var}", "--disable-debug", "--disable-dependency-tracking"
    system "make install"
    (var+'varnish').mkpath
  end
end