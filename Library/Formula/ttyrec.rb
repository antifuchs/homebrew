require 'formula'

class Ttyrec <Formula
  url 'http://0xcc.net/ttyrec/ttyrec-1.0.8.tar.gz'
  homepage 'http://0xcc.net/ttyrec/index.html.en'
  md5 'ee74158c6c55ae16327595c70369ef83'

# depends_on 'cmake'

  def install
    system "make"
    bin.install ["ttyplay", "ttyrec", "ttytime"]
    man1.install ["ttyrec.1", "ttytime.1", "ttyplay.1"]
  end
end
